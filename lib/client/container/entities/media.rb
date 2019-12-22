# encoding: UTF-8
require 'forwardable'

module Tw

  #==================================================================
  # Media クラス
  # Tw::Tweet::Entities の media メンバ
  # これは配列である。
  # Developers: https://dev.twitter.com/docs/entities#tweets
  #==================================================================
  class Media
    extend ::Forwardable
    def_delegators :@array, :[], :each, :select, :reject, :size

    # media は、
    #   Twitter::Media::Photo   # Obsolete
    #   Twitter::AnimatedGif    # Obsolete
    #   Twitter::Video          # Obsolete
    #   Twitter::VideoInfo      # Obsolete
    # の配列。

    def initialize(media)
      if !media.is_a?(Array) && media != nil then
        raise TypeError.new("media must be an Array or a NilClass but #{media.class}.")
      end

      if !!media then
        @array = media.collect {|elem| Tw::MediaElem.compose(elem)}
      else
        @array = []
      end
    end

    def to_json(*a)
      return @array.to_json(*a)
    end

  end

  #==================================================================
  # MediaElem Media クラスの要素
  #==================================================================
  class MediaElem
    private_class_method :new
    attr_reader :id, :type
    MEDIA_TYPE_PHOTO        = "photo"
    MEDIA_TYPE_ANIMATED_GIF = "animated_gif"
    MEDIA_TYPE_VIDEO        = "video"
    MEDIA_TYPE_VIDEO_INFO   = "video_info"

    def initialize()
    end

    public

    def self.compose(media_elem)
      if !media_elem.is_a?(Hash) then
        raise TypeError.new("media_elem must be a Hash but #{media_elem.class}.")
      end

      #if media_elem.is_a?(Twitter::Media::Photo) then  # Obsolete
      #  if media_elem.attrs[:type] == MEDIA_TYPE_PHOTO then
      #    return MediaElemPhotoFromGem.new(media_elem)
      #  else
      #    # returns Gems's object itself 'for now'.
      #    return media_elem
      #  end
      #elsif media_elem.is_a?(Twitter::Media::AnimatedGif) then # Obsolete
      #  if media_elem.attrs[:type] == MEDIA_TYPE_ANIMATED_GIF then
      #    return MediaElemAnimatedGifFromGem.new(media_elem)
      #  else
      #    # returns Gems's object itself 'for now'.
      #    return media_elem
      #  end
      #elsif media_elem.is_a?(Twitter::Media::Video) then  # Obsolete
      #  if media_elem.attrs[:type] == MEDIA_TYPE_VIDEO then
      #    return MediaElemVideoFromGem.new(media_elem)
      #  else
      #    # returns Gems's object itself 'for now'.
      #    return media_elem
      #  end
      #elsif media_elem.is_a?(Twitter::Media::VideoInfo) then  # Obsolete
      #  if media_elem.attrs[:type] == MEDIA_TYPE_VIDEO_INFO then
      #    return MediaElemVideoInfoFromGem.new(media_elem)
      #  else
      #    # returns Gems's object itself 'for now'.
      #    return media_elem
      #  end
      #elsif media_elem.is_a?(Hash) then
      if media_elem.is_a?(Hash) then
        if media_elem[:type] == MEDIA_TYPE_PHOTO then
          return MediaElemPhotoFromHash.new(media_elem)
        elsif media_elem[:type] == MEDIA_TYPE_ANIMATED_GIF then
          return MediaElemAnimatedGifFromHash.new(media_elem)
        elsif media_elem[:type] == MEDIA_TYPE_VIDEO then
          return MediaElemVideoFromHash.new(media_elem)
        elsif media_elem[:type] == MEDIA_TYPE_VIDEO_INFO then
          return MediaElemVideoInfoFromHash.new(media_elem)
        else
          # returns Gems's object itself 'for now'.
          return media_elem
        end
      else
        raise TypeError.new("type of media_elem must be Hash but #{media_elem}.")
      end
    end

    def to_json(*a)
    end

  end

  #==================================================================
  # MediaSizes クラス
  # ツイートの Entities の media の写真等のサイズを格納するクラス
  #==================================================================
  class MediaSizes
    def initialize(sizes)
      @sizesHash = {}
      #if sizes.is_a?(Twitter::Size) then  # Obsolete

      #  raise TypeError.new("sizez must be a Hash but #{sizes.class}.")

      #  sizes.each do |key, val|
      #    @sizesHash[key] = {
      #          :w => val.w, :h => val.h, :resize => val.resize }
      #  end
      #else
        #sizes.each do |key, val|
          #if val.is_a?(Twitter::Size) then  # Obsolete
          #
          #  raise TypeError.new("sizez must be a Hash but #{sizes.class}.")
          #
          #  @sizesHash[key] = {
          #        :w => val.w,   :h => val.h,   :resize => val.resize   }
          #else
          #  @sizesHash[key] = {
          #        :w => val[:w], :h => val[:h], :resize => val[:resize] }
          #end
        #end
      #end
      sizes.each do |key, val|
        @sizesHash[key] = {:w => val[:w], :h => val[:h], :resize => val[:resize] }
      end
    end

    def to_json(*a)
      return @sizesHash.to_json(*a)
    end
  end

  #==================================================================
  # MediaElemPhoto クラス
  # Media クラスの要素
  #==================================================================
  class MediaElemPhoto < MediaElem
    public_class_method :new
    attr_reader :id, :media_url, :media_url_https, :url, :display_url,
                :expanded_url, :type, :sizes, :indices

    # About sizes:
    # The media_url defaults to medium but you can retrieve the media in 
    # different sizes by appending a colon + the size key (for example: 
    # http://pbs.twimg.com/media/A7EiDWcCYAAZT1D.jpg:thumb). 
    # Each available size comes with three attributes that describe it:
    #   w:      the width (in pixels) of the media in this particular size
    #   h:      the height (in pixels) of the media in this particular size
    #   resize: how we resized the media to this particular size (can be 
    #           crop or fit) 

    def initialize(media_elem)
      super()

      @id              = nil
      @media_url       = nil # メディアの URL
      @media_url_https = nil # メディアの SSL URL
      @url             = nil # メディア URL（展開）
      @display_url     = nil
      @expanded_url    = nil
      @type            = MEDIA_TYPE_PHOTO # only "photo" for now
      @sizes           = nil
      @indices         = nil
    end

    def to_json(*a)
      return {
        :id              => @id,
        :media_url       => @media_url,        # メディアの URL
        :media_url_https => @media_url_https,  # メディアの SSL URL
        :url             => @url,              # メディア URL（展開）
        :display_url     => @display_url,
        :expanded_url    => @expanded_url,
        :type            => @type,             # only "photo" for now
        :sizes           => @sizes,
        :indices         => @indices,
      }.to_json(*a)
    end
  end


  #==================================================================
  # MediaElemPhotoFromGem クラス
  # Media クラスの要素
  # Gems: Twitter::Media::Photo  # Obsolete
  #==================================================================
  #class MediaElemPhotoFromGem < MediaElemPhoto
  #  # media_elem は Twitter::Media::Photo クラス。  # Obsolete
  #  def initialize(media_elem)
  #    raise RuntimeError.new("Obsolete. Don't call me.")
  #    super(media_elem)
  #    @id              = media_elem.id
  #    @media_url       = media_elem.media_url       # メディアの URL
  #    @media_url_https = media_elem.media_url_https # メディアの SSL URL
  #    @url             = media_elem.url             # メディア URL（展開）
  #    @display_url     = media_elem.display_url
  #    @expanded_url    = media_elem.expanded_url
  #    @type            = MEDIA_TYPE_PHOTO           # only "photo" for now
  #    @sizes           = MediaSizes.new(media_elem.sizes)
  #    @indices         = media_elem.indices
  #  end
  #end

  #==================================================================
  # MediaElemPhotoFromHash クラス
  # Media クラスの要素
  #==================================================================
  class MediaElemPhotoFromHash < MediaElemPhoto
    def initialize(media_elem)
      super(media_elem)
      @id              = media_elem[:id]
      @media_url       = media_elem[:media_url]       # メディアの URL
      @media_url_https = media_elem[:media_url_https] # メディアの SSL URL
      @url             = media_elem[:url]             # メディア URL（展開）
      @display_url     = media_elem[:display_url]
      @expanded_url    = media_elem[:expanded_url]
      @type            = MEDIA_TYPE_PHOTO           # only "photo" for now
      @sizes           = MediaSizes.new(media_elem[:sizes])
      @indices         = media_elem[:indices]
    end
  end

  #==================================================================
  # MediaElemAnimatedGif クラス
  # Media クラスの要素
  #==================================================================
  class MediaElemAnimatedGif < MediaElem
    public_class_method :new
    attr_reader :id, :media_url, :media_url_https, :url, :display_url,
                :expanded_url, :type, :sizes, :indices

    # About sizes:
    # The media_url defaults to medium but you can retrieve the media in 
    # different sizes by appending a colon + the size key (for example: 
    # http://pbs.twimg.com/media/A7EiDWcCYAAZT1D.jpg:thumb). 
    # Each available size comes with three attributes that describe it:
    #   w:      the width (in pixels) of the media in this particular size
    #   h:      the height (in pixels) of the media in this particular size
    #   resize: how we resized the media to this particular size (can be 
    #           crop or fit) 

    def initialize(media_elem)
      super()

      @id              = nil
      @media_url       = nil # メディアの URL
      @media_url_https = nil # メディアの SSL URL
      @url             = nil # メディア URL（展開）
      @display_url     = nil
      @expanded_url    = nil
      @type            = MEDIA_TYPE_ANIMATED_GIF
      @sizes           = nil
      @indices         = nil
    end

    def to_json(*a)
      return {
        :id              => @id,
        :media_url       => @media_url,        # メディアの URL
        :media_url_https => @media_url_https,  # メディアの SSL URL
        :url             => @url,              # メディア URL（展開）
        :display_url     => @display_url,
        :expanded_url    => @expanded_url,
        :type            => @type,
        :sizes           => @sizes,
        :indices         => @indices,
      }.to_json(*a)
    end
  end

  #==================================================================
  # MediaElemAnimatedGifFromGem クラス
  # Media クラスの要素
  # Gems: Twitter::Media::AnimatedGif  # Obsolete
  #==================================================================
  class MediaElemAnimatedGifFromGem < MediaElemAnimatedGif
    # media_elem は Twitter::Media::AnimatedGif クラス。  # Obsolete
    def initialize(media_elem)
      raise RuntimeError.new("Obsolete. Don't call me.")
      super(media_elem)
      @id              = media_elem.id
      @media_url       = media_elem.media_url       # メディアの URL
      @media_url_https = media_elem.media_url_https # メディアの SSL URL
      @url             = media_elem.url             # メディア URL（展開）
      @display_url     = media_elem.display_url
      @expanded_url    = media_elem.expanded_url
      @type            = MEDIA_TYPE_ANIMATED_GIF
      @sizes           = MediaSizes.new(media_elem.sizes)
      @indices         = media_elem.indices
    end
  end

  #==================================================================
  # MediaElemAnimatedGifFromHash クラス
  # Media クラスの要素
  #==================================================================
  class MediaElemAnimatedGifFromHash < MediaElemAnimatedGif
    def initialize(media_elem)
      super(media_elem)
      @id              = media_elem[:id]
      @media_url       = media_elem[:media_url]       # メディアの URL
      @media_url_https = media_elem[:media_url_https] # メディアの SSL URL
      @url             = media_elem[:url]             # メディア URL（展開）
      @display_url     = media_elem[:display_url]
      @expanded_url    = media_elem[:expanded_url]
      @type            = MEDIA_TYPE_ANIMATED_GIF
      @sizes           = MediaSizes.new(media_elem[:sizes])
      @indices         = media_elem[:indices]
    end
  end

  #==================================================================
  # MediaElemVideo クラス
  # Media クラスの要素
  #==================================================================
  class MediaElemVideo < MediaElem
    public_class_method :new
    attr_reader :id, :media_url, :media_url_https, :url, :display_url,
                :type, :sizes, :indices, :video_info

    # About sizes:
    # The media_url defaults to medium but you can retrieve the media in 
    # different sizes by appending a colon + the size key (for example: 
    # http://pbs.twimg.com/media/A7EiDWcCYAAZT1D.jpg:thumb). 
    # Each available size comes with three attributes that describe it:
    #   w:      the width (in pixels) of the media in this particular size
    #   h:      the height (in pixels) of the media in this particular size
    #   resize: how we resized the media to this particular size (can be 
    #           crop or fit) 

    def initialize(media_elem)
      super()

      @id              = nil
      @media_url       = nil # メディアの URL
      @media_url_https = nil # メディアの SSL URL
      @url             = nil # メディア URL（展開）
      @display_url     = nil
      @type            = MEDIA_TYPE_VIDEO
      @sizes           = nil
      @indices         = nil
      @video_info      = nil
    end

    def to_json(*a)
      return {
        :id              => @id,
        :media_url       => @media_url,        # メディアの URL
        :media_url_https => @media_url_https,  # メディアの SSL URL
        :url             => @url,              # メディア URL（展開）
        :display_url     => @display_url,
        :type            => @type,
        :sizes           => @sizes,
        :indices         => @indices,
        :video_info      => @video_info,
      }.to_json(*a)
    end
  end

  #==================================================================
  # MediaElemVideoFromGem クラス
  # Media クラスの要素
  # Gems: Twitter::Media::Video  # Obsolete
  #==================================================================
  class MediaElemVideoFromGem < MediaElemVideo
    # media_elem は Twitter::Media::Video クラス。 # Obsolete
    def initialize(media_elem)
      raise RuntimeError.new("Obsolete. Don't call me.")
      super(media_elem)
      @id              = media_elem.id
      @media_url       = media_elem.media_url       # メディアの URL
      @media_url_https = media_elem.media_url_https # メディアの SSL URL
      @url             = media_elem.url             # メディア URL（展開）
      @display_url     = media_elem.display_url
      @type            = MEDIA_TYPE_VIDEO
      @sizes           = MediaSizes.new(media_elem.sizes)
      @indices         = media_elem.indices
      @video_info      = media_elem.video_info
    end
  end

  #==================================================================
  # MediaElemVideoFromHash クラス
  # Media クラスの要素
  #==================================================================
  class MediaElemVideoFromHash < MediaElemVideo
    def initialize(media_elem)
      super(media_elem)
      @id              = media_elem[:id]
      @media_url       = media_elem[:media_url]       # メディアの URL
      @media_url_https = media_elem[:media_url_https] # メディアの SSL URL
      @url             = media_elem[:url]             # メディア URL（展開）
      @display_url     = media_elem[:display_url]
      @type            = MEDIA_TYPE_VIDEO
      @sizes           = MediaSizes.new(media_elem[:sizes])
      @indices         = media_elem[:indices]
      @video_info      = MediaVideoInfo.new(media_elem[:video_info])
    end
  end

  #==================================================================
  # MediaVideoInfo クラス
  # ツイートの Entities の media のビデオ情報の配列を格納するクラス
  #==================================================================
  class MediaVideoInfo
    attr_reader :aspect_ratio, :duration_millis, :variants
    def initialize(video_info)
      @aspect_ratio    = video_info[:aspect_ratio]
      @duration_millis = video_info[:duration_millis]
      @variants        = MediaVideoVariants.new(video_info[:variants])
    end
    def to_json(*a)
      return {
        :aspect_ratio    => @aspect_ratio,
        :duration_millis => @duration_millis,
        :variants        => @variants,
      }.to_json(*a)
    end
  end

  #==================================================================
  # MediaVideoVariants クラス
  # ツイートの Entities の video の variants 情報の配列を格納するクラス
  #==================================================================
  class MediaVideoVariants
    def initialize(variants)
      if variants.nil? then
        @array = nil
      else
        @array = variants.map {|elem| MediaVideoVariantElem.new(elem)}
      end
    end
    def to_json(*a)
      return @array.to_json(*a)
    end
  end

  #==================================================================
  # MediaVideoVariantElem クラス
  # ツイートの Entities の video の variant 情報を格納するクラス
  #==================================================================
  class MediaVideoVariantElem
    attr_reader :bitrate, :content_type, :url
    def initialize(variant_elem)
      @bitrate      = variant_elem[:bitrate]
      @content_type = variant_elem[:content_type]
      @url          = variant_elem[:url]
    end
    def bitrate?()
      return !!@bitrate
    end
    def to_json(*a)
      hash = {}
      hash[:bitrate]      = @bitrate if self.bitrate?
      hash[:content_type] = @content_type
      hash[:url]          = @url
      return hash.to_json(*a)
    end
  end

end

=begin

irb(main):060:0> data
=> {"sizes"=>{"medium"=>{"w"=>600, "h"=>399, "resize"=>"fit"}, "thumb"=>{"w"=>150, "h"=>150, "resize"=>"crop"}, "small"=>{"w"=>340, "h"=>226, "resize"=>"fit"}, "large"=>{"w"=>800, "h"=>532, "resize"=>"fit"}}}

irb(main):059:0> data["sizes"].keys.each do |key| puts "#{key}: #{data["sizes"][key]}" end
medium: {"w"=>600, "h"=>399, "resize"=>"fit"}
thumb: {"w"=>150, "h"=>150, "resize"=>"crop"}
small: {"w"=>340, "h"=>226, "resize"=>"fit"}
large: {"w"=>800, "h"=>532, "resize"=>"fit"}

=end
