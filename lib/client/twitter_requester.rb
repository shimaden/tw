# encoding: utf-8
require File.expand_path('../utility/cgi_escape', File.dirname(__FILE__))

module Tw
  class TwitterRequester
    attr_reader :new_auth
    include Smdn::CGI

    def initialize(new_auth)
      @new_auth = new_auth
    end

    #-------------------------------------------------------
    # Twitter API に GET
    #-------------------------------------------------------
    def get(endpoint, options, header = {})
      url = endpoint + self.cgi_escape(options)
      http_response = @new_auth.access_token.get(url)
      if !http_response.is_a?(Net::HTTPSuccess) then
        error = Tw::Error.create(http_response: http_response)
        raise error
      end
      json = JSON.parse(http_response.body, :symbolize_names => true)
      return json
    end

    #-------------------------------------------------------
    # Twitter API に POST
    #-------------------------------------------------------
    def post(endpoint, options, header = {})
      http_response = @new_auth.access_token.post(endpoint, options, header)
      if !http_response.is_a?(Net::HTTPSuccess) then
        error = Tw::Error.create(http_response: http_response)
        raise error
      end
      json = JSON.parse(http_response.body, :symbolize_names => true)
      return json
    end

  end

end
