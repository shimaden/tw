# encoding: utf-8
require 'delegate'

module Tw

  class ExtendedMediaElement
    attr_reader :attrs, :id, :indices, :media_url, :media_url_https,
                :url, :display_url, :expanded_url, :type, :sizes

    class Sizes
      attr_reader :attrs, :small, :thumb, :medium, :large
      def initialize(sizes)
        @attrs = sizes
        @small = sizes[:small]
        @thumb = sizes[:thumb]
        @medium = sizes[:medium]
        @large  = sizes[:large]
      end
      def to_json(*a)
        return @attrs.to_json(*a)
      end
    end

    class VideoInfo
      attr_reader :attrs, :aspect_ratio, :duration_millis, :variants
      class Variant
        attr_reader :attrs, :bitrate, :content_type, :url
        def initialize(variant)
          @attrs        = variant
          @bitrate      = variant[:bitrate]
          @content_type = variant[:content_type]
          @url          = variant[:url]
        end
        def bitrate?
          return @bitrate != nil
        end
        def to_json(*a)
          return @attrs.to_json(*a)
        end
      end

      def initialize(video_info)
        @attrs           = video_info
        if !!video_info then
          @aspect_ratio    = video_info[:aspect_ratio]
          @duration_millis = video_info[:duration_millis]
          @variants        = video_info[:variants].collect{|e| Variant.new(e)}
        else
          @aspect_ratio    = nil
          @duration_millis = nil
          @variants        = nil
        end
      end
      def duration_millis?
        return !!@duration_millis
      end
      def to_json(*a)
        return @attrs.to_json(*a)
      end
    end

    class AdditionalMediaInfo
      attr_reader :attrs, :title, :description, :embeddable, :monetizable
      def initialize(additional_media_info)
        @attrs       = additional_media_info
        if !!additional_media_info then
          @title       = additional_media_info[:title]
          @description = additional_media_info[:description]
          @embeddable  = additional_media_info[:embeddable]
          @monetizable = additional_media_info[:monetizable]
        else
          @title       = nil
          @description = nil
          @embeddable  = nil
          @monetizable = nil
        end
      end
      def to_json(*a)
        return @attrs.to_json(*a)
      end
    end

    def initialize(media)
      @attrs = media
      @id              = media[:id]
      @indices         = media[:indices]
      @media_url       = media[:media_url]
      @media_url_https = media[:media_url_https]
      @url             = media[:url]
      @display_url     = media[:display_url]
      @expanded_url    = media[:expanded_url]
      @type            = media[:type]
      @sizes           = Sizes.new(media[:sizes])
    end
    def supported_media_type?
      return true
    end
    def to_json(*a)
      return @attrs.to_json(*a)
    end
  end

  class ExtendedMediaUnsupportedTypeElement < ExtendedMediaElement
    def initialize(media)
      super(media)
    end
    def supported_media_type?
      return false
    end
  end

  class ExtendedMediaPhotoElement < ExtendedMediaElement
    def initialize(media)
      super(media)
    end
  end

  class ExtendedMediaAnimatedGifElement < ExtendedMediaElement
    attr_reader :video_info
    def initialize(media)
      super(media)
      @video_info = VideoInfo.new(media[:video_info]) if !!media[:video_info]
    end
    def video_info?
      return !!@video_info
    end
  end

  class ExtendedMediaVideoElement < ExtendedMediaElement
    attr_reader :video_info, :additional_media_info
    def initialize(media)
      super(media)
      @video_info = VideoInfo.new(media[:video_info]) if !!media[:video_info]
      @additional_media_info = AdditionalMediaInfo.new(media[:additional_media_info]) if !!media[:additional_media_info]
    end
    def video_info?
      return !!@video_info
    end
    def additional_media_info?
      return !!@additional_media_info
    end
    def mp4?
      return !!self.video_info.variants.find{|e| e.content_type == "video/mp4"}
    end
    def best_mp4_url()
      mp4 = self.video_info.variants.select{|e| e.content_type == "video/mp4"
                                  }.sort_by{|e| e.bitrate.to_i}
      if mp4.size > 0 then
        return mp4.last.url
      else
        return nil
      end
    end
  end

  class ExtendedMedia < DelegateClass(::Array)
    attr_reader :attrs
    def initialize(extended_media)
      if !extended_media.is_a?(::Array) then
        raise ::TypeError.new("extended_media must be Array but #{extended_media.class}.")
      end
      super([])
      @attrs = extended_media
      extended_media.each do |elem|
        case elem[:type]
        when "photo" then
          obj = ExtendedMediaPhotoElement.new(elem)
        when "video" then
          obj = ExtendedMediaVideoElement.new(elem)
        when "animated_gif" then
          obj = ExtendedMediaAnimatedGifElement.new(elem)
        else
          obj = ExtendedMediaUnsupportedTypeElement.new(elem)
        end
        __getobj__.push(obj)
      end
    end
    def to_json(*a)
      return @attrs.to_json(*a)
    end

  end

end
