require 'memoizable'

module Tw
  class TwitterConfiguration
    include Memoizable

    # @return [Array<String>]
    attr_reader :non_username_paths
    # @return [Integer]
    attr_reader :characters_reserved_per_media, :max_media_per_upload,
                :photo_size_limit, :short_url_length, :short_url_length_https
    alias short_uri_length short_url_length
    alias short_uri_length_https short_url_length_https

    # Returns an array of photo sizes
    #
    def photo_sizes
      @attrs.fetch(:photo_sizes, []).inject({}) do |object, (key, value)|
        object[key] = Size.new(value)
        object
      end
    end
    memoize :photo_sizes
  end
end
