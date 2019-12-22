# encoding: utf-8
module Tw

  class Error < ::StandardError
    attr_reader :code, :api_message, :api_code, :rate_limit

    API_LIMIT_FIELDS = [
      'X-Rate-Limit-Limit',
      'X-Rate-Limit-Remaining',
      'X-Rate-Limit-Reset',
    ].freeze

    def initialize(http_response)
      if !http_response.is_a?(Net::HTTPResponse) then
        raise TypeError.new("http_response must be Net::HTTPResponse but #{http_response.class}.")
      end
      @http_response = http_response
      @code = Integer(@http_response.code)

      if self.has_json_body?(@http_response) then
        body = JSON.parse(@http_response.body, :symbolize_names => true)
        parsed_error = self.parse_error(body)
        @api_message  = parsed_error[0]
        @api_code     = Integer(parsed_error[1]) if parsed_error[1] != nil
      end

      super(http_response.message)

      @rate_limit = {}
      http_response.each_capitalized do |field, value|
        api_limit_field = API_LIMIT_FIELDS.find{|e| field =~ /#{e}/i}
        if api_limit_field != nil then
          @rate_limit[api_limit_field] = Integer(value)
        end
      end
    end

    protected

    def has_json_body?(http_response)
      return http_response.content_length != nil  \
          && http_response.content_length > 0     \
          && http_response.body.strip =~ /^{.*}$/
    end

    def parse_error(body)
      if body.nil? then
        return ['', nil]
      elsif body[:error] then
        return [body[:error], nil]
      elsif body[:errors] then
        return extract_message_from_errors(body)
      end
    end

    def extract_message_from_errors(body)
      first = Array(body[:errors]).first
      if first.is_a?(::Hash) then
        return [first[:message].chomp, first[:code]]
      else
        return [first.chomp, nil]
      end
    end


    # Raised when Twitter returns a 4xx HTTP status code
    class ClientError < Error; end
  
    # Raised when Twitter returns the HTTP status code 400
    class BadRequest < ClientError; end
  
    # Raised when Twitter returns the HTTP status code 401
    class Unauthorized < ClientError; end
  
    # Raised when Twitter returns the HTTP status code 403
    class Forbidden < ClientError; end
  
    class ConfigurationError < ::ArgumentError; end
  
    # Raised when a Tweet includes media that doesn't have a to_io method
    class UnacceptableIO < StandardError
      def initialize
        super('The IO object for media must respond to to_io')
      end
    end
  
    # Raised when a Tweet has already been favorited
    class AlreadyFavorited < Forbidden; end
  
    # Raised when a Tweet has already been retweeted
    class AlreadyRetweeted < Forbidden; end
  
    # Raised when a Tweet has already been posted
    class DuplicateStatus < Forbidden; end
    AlreadyPosted = DuplicateStatus
  
    # Raised when Twitter returns the HTTP status code 404
    class NotFound < ClientError; end
  
    # Raised when Twitter returns the HTTP status code 406
    class NotAcceptable < ClientError; end
  
    # Raised when Twitter returns the HTTP status code 408
    class RequestTimeout < ClientError; end
  
    # Raised when Twitter returns the HTTP status code 422
    class UnprocessableEntity < ClientError; end
  
    # Raised when Twitter returns the HTTP status code 429
    class TooManyRequests < ClientError; end
    EnhanceYourCalm = TooManyRequests
    RateLimited = TooManyRequests
  
    # Raised when Twitter returns a 5xx HTTP status code
    class ServerError < Error; end
  
    # Raised when Twitter returns the HTTP status code 500
    class InternalServerError < ServerError; end
  
    # Raised when Twitter returns the HTTP status code 502
    class BadGateway < ServerError; end
  
    # Raised when Twitter returns the HTTP status code 503
    class ServiceUnavailable < ServerError; end
  
    # Raised when Twitter returns the HTTP status code 504
    class GatewayTimeout < ServerError; end

    ERRORS = {
      400 => Tw::Error::BadRequest,
      401 => Tw::Error::Unauthorized,
      403 => Tw::Error::Forbidden,
      404 => Tw::Error::NotFound,
      406 => Tw::Error::NotAcceptable,
      408 => Tw::Error::RequestTimeout,
      420 => Tw::Error::EnhanceYourCalm,
      422 => Tw::Error::UnprocessableEntity,
      429 => Tw::Error::TooManyRequests,
      500 => Tw::Error::InternalServerError,
      502 => Tw::Error::BadGateway,
      503 => Tw::Error::ServiceUnavailable,
      504 => Tw::Error::GatewayTimeout,
    }

    FORBIDDEN_MESSAGES = {
      'Status is a duplicate.' => Tw::Error::DuplicateStatus,
      'You have already favorited this status.' => Tw::Error::AlreadyFavorited,
      'sharing is not permissible for this status (Share validations failed)' => Tw::Error::AlreadyRetweeted,
    }

    class TwitterCommError < Error; end

    class VideoUploadError < TwitterCommError
      def initialize(http_response, message)
        super(http_response)
        @message = "#{message}: #{http_response.code} #{http_response.message}"
      end
      public
      def message()
        return @message
      end
    end

    def self.create(http_response: nil, video_upload_error: nil)
      do_perform = (http_response != nil && video_upload_error == nil) \
                || (http_response == nil && video_upload_error != nil)
      if !do_perform then
        raise ::ArgumentError.new("Only one parameter must be given.")
      end

      if http_response.is_a?(Net::HTTPResponse) then
        error = FORBIDDEN_MESSAGES[http_response.message]
        return error.new(http_response) if !error.nil?

        error = ERRORS[Integer(http_response.code)]
        return error.new(http_response) if !error.nil?

        raise ::RuntimeError.new("Unsupported type of Net::HTTPResponse: #{http_response.class}: #{http_response.code} #{http_response.message}")
      end

      if video_upload_error.is_a?(::Hash) then
        h = video_upload_error
        if !(h.has_key?(:context) && h.has_key?(:http_response)) then
          raise ::ArgumentError.new("Hash video_upload_error has unsufficient keys.")
        end
        message = "Video upload error: INIT"     if h[:context] == :init
        message = "Video upload error: APPEND"   if h[:context] == :append
        message = "Video upload error: FINALIZE" if h[:context] == :finalize
        message = "Video upload error: STATUS"   if h[:context] == :status
        if message.nil? then
          raise ::RuntimeError.new("Unsupported value for :context key: #{h[:context]}")
        end
        return VideoUploadError.new(h[:http_response], message)
      end

      raise ::ArgumentError.new("Invalid parameters are given.")
    end

  end


end
