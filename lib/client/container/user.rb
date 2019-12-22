# encoding: UTF-8
require 'json'
require 'time'
require File.expand_path('entities/entities_for_user', File.dirname(__FILE__))

module Tw

  #----------------------------------------------------------------------
  # Tw::User を生成する時に、メンバ User.status_id が nil でない時に、
  # その status （ツイート）も読み込むかを判定するクラス。
  #----------------------------------------------------------------------
  class IncStat
    private_class_method :new
    def self.compose(yes)
      if yes then
        IncStatYes.new
      else
        IncStatNo.new
      end
    end
  end

  class IncStatYes < IncStat
    public_class_method :new
  end

  class IncStatNo < IncStat
    public_class_method :new
  end


  #----------------------------------------------------------------------
  # AbstractUser クラス
  #----------------------------------------------------------------------
  class AbstractUser
    private_class_method :new
    attr_reader :id, :screen_name, :name, :protected, :verified, :lang,
        :description,
        :location, :url, :created_at, :time_zone, :utc_offset, :is_translator,
        :geo_enabled,
        :follow_request_sent, :following, :followed_by,
        :statuses_count,
        :listed_count,
        :favorites_count, :friends_count, :followers_count,
        :status, :entities,
 
        :profile_background_color,
        :profile_background_image_url,
        :profile_background_image_url_https,
        :profile_background_tile,
        :profile_image_url,
        :profile_image_url_https,
        :profile_banner_url,
        :profile_link_color,
        :profile_sidebar_border_color,
        :profile_sidebar_fill_color,
        :profile_text_color,
        :profile_use_background_image,
        :has_extended_profile,
        :default_profile,
        :default_profile_image,

        :attrs

    INC_STAT_YES = IncStat.compose(true)
    INC_STAT_NO  = IncStat.compose(false)

    def initialize()
      @id                    = nil
      @screen_name           = nil
      @name                  = nil
      @protected             = nil
      @verified              = nil
      @lang                  = nil
      @description           = nil
      @location              = nil
      @url                   = nil
      @created_at            = nil
      @time_zone             = nil
      @utc_offset            = nil
      @is_translator         = nil
      @geo_enabled           = nil
      @follow_request_sent   = nil
      @following             = nil  # 自分がこのユーザをフォローしているか。
      @followed_by           = nil
      @statuses_count        = nil
      @listed_count          = nil
      @favorites_count       = nil
      @friends_count         = nil
      @followers_count       = nil
      @status                = nil  # このユーザのもっとも最近のツイート
      @entities              = nil

      @profile_background_color           = nil
      @profile_background_image_url       = nil
      @profile_background_image_url_https = nil
      @profile_background_tile            = nil
      @profile_image_url                  = nil
      @profile_image_url_https            = nil
      @profile_banner_url                 = nil
      @profile_link_color                 = nil
      @profile_sidebar_border_color       = nil
      @profile_sidebar_fill_color         = nil
      @profile_text_color                 = nil
      @profile_use_background_image       = nil
      @has_extended_profile               = nil
      @default_profile       = nil
      @default_profile_image = nil

      @attrs                 = nil
    end

    def tweet_accessible?
      if @protected then
        if @following then
          accessible = true
        else
          accessible = false
        end
      else
        accessible = true
      end
      return accessible
    end

    def status?
      return @status ? true : false
    end

    def url?()
      return @url.not_nil?
    end

    def to_s
      return nil
    end

    def format(fmt)
      return nil
    end

    def to_json(*a)
    end
  end

  #----------------------------------------------------------------------
  # User クラス
  #----------------------------------------------------------------------
  class User < AbstractUser
    private_class_method :new

    def initialize()
      super()
    end

    def self.compose(user, followed_by)
      if user.nil? then
        return nil
      end
      public_class_method(:new)
      begin
        if user.is_a?(Hash) then
          return UserFromHash.new(user, followed_by)
        else
          raise TypeError.new("user must be a Hash but #{user.class}.")
        end
      ensure
        private_class_method(:new)
      end
    end

    def url?()
      return @url.not_nil?
    end

    def to_s
      home_url = "https://twitter.com/#{@screen_name}"
      locked = @protected ? ":LCKD" : ""
      return "@#{@screen_name} (#{@id})#{locked}:#{@created_at} #{home_url}"
    end

  end

  #----------------------------------------------------------------------
  # UserFromHash クラス
  #----------------------------------------------------------------------
  class UserFromHash < User
    private_class_method :new
    attr_reader :attrs

    def initialize(user, followed_by)
      super()
      if !user.is_a?(Hash) then
        raise TypeError.new("\'user\' must be Hash but #{user.class}.")
      end

      @attrs             = user

      @id                = user[:id]          # User ID
      @screen_name       = user[:screen_name] # @usakonigohan
      @name              = user[:name]        # うさこにごはん
      @protected         = user[:protected]   # 鍵付きユーザか
      @verified          = user[:verified]    # 承認ユーザか
      @lang              = user[:lang]        # "ja" とか
      @description       = user[:description] # プロフィール文章
      @location          = user[:location]    # プロフィールに登録した場所。
      @url               = user[:url]         # プロフィールのURL
      @created_at        = Time.parse(user[:created_at])
      @time_zone         = user[:time_zone]
      @utc_offset        = user[:utc_offset]
      @is_translator     = user[:is_translator] # 翻訳者登録しているか（？）
      @geo_enabled       = user[:geo_enabled] # 位置情報が利用可能か
      @follow_request_sent = user[:follow_request_sent] # (自分が)フォロー・リクエストをしているか
      @following         = user[:following] # (自分が)フォローしているか
      @followed_by       = followed_by
      @statuses_count    = user[:statuses_count] # ツイート数
      @listed_count      = user[:listed_count]   # リスト登録されている数
      @favorites_count   = user[:favourites_count] || user[:favorites_count] # なぜかここだけ英式
      @friends_count     = user[:friends_count]   # フォロー数
      @followers_count   = user[:followers_count] # フォロワー数
      if user.has_key?(:status) then  # ツイートを含ませるAPIもある
        @status          = Tw::Tweet.compose(user[:status], followed_by)
      else
        @status          = nil
      end
      if user.has_key?(:entities) then
        @entities        = Tw::UserEntities.new(user[:entities])
      else
      end

      @profile_background_color     = user[:profile_background_color]
      @profile_background_image_url = user[:profile_background_image_url]
      @profile_background_image_url_https = user[:profile_background_image_url_https]
      @profile_background_tile      = user[:profile_background_tile]
      @profile_image_url            = user[:profile_image_url]
      @profile_image_url_https      = user[:profile_image_url_https]
      @profile_banner_url           = user[:profile_banner_url]
      @profile_link_color           = user[:profile_link_color]
      @profile_sidebar_border_color = user[:profile_sidebar_border_color]
      @profile_sidebar_fill_color   = user[:profile_sidebar_fill_color]
      @profile_text_color           = user[:profile_text_color]
      @profile_use_background_image = user[:profile_use_background_image]
      @has_extended_profile         = user[:has_extended_profile]

      @default_profile       = user[:default_profile]
      @default_profile_image = user[:default_profile_image]
    end

    def to_json(*a)
      hash = {}
      @attrs.each do |key, val|
        hash[key] = val
        if key == :following then
          hash[:followed_by] = @followed_by if !@followed_by.nil?
        elsif key == :favourites_count then
          hash[:favorites_count] = @attrs[:favourites_count]
        end
      end
      hash[:created_at] = @created_at
      hash[:status]     = @status   if @attrs.has_key?(:status)
      hash[:entities]   = @entities if @attrs.has_key?(:entities)
      return hash.to_json(*a)
    end

  end

  #----------------------------------------------------------------------
  # NilUser クラス
  #----------------------------------------------------------------------
  class NilUser < User
    public_class_method :new

    def initialize(params)
      super()
      @id                = params[:id]
      @screen_name       = params[:screen_name]
      @name              = nil
      @protected         = nil
      @verified          = nil
      @lang              = nil
      @description       = nil
      @location          = nil
      @url               = nil
      @created_at        = nil
      @time_zone         = nil
      @utc_offset        = nil
      @is_translator     = nil
      @geo_enabled       = nil
      @follow_request_sent = nil
      @following             = nil
      @followed_by           = nil
      @statuses_count        = nil
      @listed_count          = nil
      @favorites_count       = nil
      @friends_count         = nil
      @followers_count       = nil
      @status                = nil
      @entities              = nil

      @profile_background_color           = nil
      @profile_background_image_url       = nil
      @profile_background_image_url_https = nil
      @profile_background_tile            = nil
      @profile_image_url                  = nil
      @profile_image_url_https            = nil
      @profile_banner_url                 = nil
      @profile_link_color                 = nil
      @profile_sidebar_border_color       = nil
      @profile_sidebar_fill_color         = nil
      @profile_text_color                 = nil
      @profile_use_background_image       = nil
      @has_extended_profile               = nil
      @default_profile       = nil
      @default_profile_image = nil

    end
  end

#------------------------------------------------------------------------
end
