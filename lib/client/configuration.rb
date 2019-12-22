# encoding: UTF-8
require 'twitter-text'

module Tw

  class Configuration
    include ::Twitter::TwitterText::Validation

    END_POINT = '/1.1/help/configuration.json'

    # filename  : the file name for cache data.
    # permission: for the file.
    # interval  : time interval to update the cache.
    def initialize(requester, filename, permission, interval)
      if requester.is_a?(Tw::TwitterRequester) then
        @requester = requester
      else
        raise ::TypeError.new("Use Tw::TwitterRequester instead of #{requester.class}.")
      end
      @configArr = FileCashableArray.new(filename, permission, interval)
    end

    protected

    # Get configuration
    def configuration()
      if @configArr.file_old? then
        @configArr.clear()

        params = {}
        hash = @requester.get(END_POINT, params)

        @configuration = hash
        @configArr.push(hash.to_json())
        @configArr.save_to_file()
      else
        if @configuration.nil? then
          @configArr.load_from_file()
          hash = JSON.parse(@configArr[0], :symbolize_names => true)
          @configuration = hash
        else
        end
      end
      return @configuration
    end

    def short_url_length_https()
      self.configuration()
      return @configuration[:short_url_length_https]
    end

    def short_url_length()
      self.configuration()
      return @configuration[:short_url_length]
    end

    public

    def characters_reserved_per_media()
      self.configuration()
      return @configuration[:characters_reserved_per_media]
    end

    #def length_shortened_by_t_co(message)
    #  options = {
    #    :short_url_length_https => self.short_url_length_https(),
    #    :short_url_length       => self.short_url_length(),
    #  }
    #  len = self.tweet_length(message, options)
    #  return len
    #end
    def weightened_length_shortened_by_t_co(message)
      options = {
        :short_url_length_https => self.short_url_length_https(),
        :short_url_length       => self.short_url_length(),
      }
      #len_old = self.tweet_length(message, options)
      parse_results = self.parse_tweet(message, options)
      len = parse_results[:weighted_length]
#$stderr.puts("len     = #{len}")
#$stderr.puts("len_old = #{len_old}")
      return len
    end

    ## 普通に数えた本文の長さ - URL短縮で短くなった本文の長さ
    #def length_to_shorten_message(message)
    #  original_length  = message.length
    #  shortened_length = self.length_shortened_by_t_co(message)
    #  return original_length - shortened_length
    #end
    # 普通に数えた本文の長さ - URL短縮で短くなった本文の長さ
    def weightened_length_to_shorten_message(message)
      #original_length  = message.length
      shortened_length = self.weightened_length_shortened_by_t_co(message)
      return shortened_length
    end

    def max_media_per_upload()
      self.configuration()
      return @configuration[:max_media_per_upload]
    end

    def photo_size_limit()
      self.configuration()
      return @configuration[:photo_size_limit]
    end

  end

end
