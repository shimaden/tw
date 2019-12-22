# encoding: UTF-8
# 公式の説明
#   Entities クラス http://rdoc.info/gems/twitter/Twitter/Entities#entities%3F-instance_method
#                   https://dev.twitter.com/docs/entities

require File.expand_path 'hashtags', File.dirname(__FILE__)
require File.expand_path 'media', File.dirname(__FILE__)
require File.expand_path 'symbols', File.dirname(__FILE__)
require File.expand_path 'urls_tweet', File.dirname(__FILE__)
require File.expand_path 'user_mentions', File.dirname(__FILE__)

module Tw

  #----------------------------------------------------------------------
  # Abstract Entities class
  #----------------------------------------------------------------------
  class AbstractEntities
    private_class_method :new
    attr_reader :hashtags, :media, :symbols, :urls, :user_mentions

    def initialize()
        @hashtags      = nil
        @media         = nil
        @symbols       = nil
        @urls          = nil
        @user_mentions = nil
    end

    def hashtags?()
      return @hashtags.not_nil?
    end

    def media?()
      return !@media.nil? && @media.size > 0
    end

    def symbols?
      return @symbols.not_nil?
    end

    def urls?
      return @urls.not_nil?
    end

    def user_mentions?
      return @user_mentions.not_nil? && @user_mentions.size > 0
    end

    def to_json(*a)
      return {
        :hashtags      => @hashtags,
        :media         => @media,
        :symbols       => @symbols,
        :urls          => @urls,
        :user_mentions => @user_mentions
      }.to_json(*a)
    end

  end

  #----------------------------------------------------------------------
  # Entities class
  #----------------------------------------------------------------------
  class Entities < AbstractEntities
    private_class_method :new

    def initialize()
      super()
    end

    def self.compose(tweet)
      if tweet.is_a?(Hash) then
        return Tw::EntitiesFromHash.new(tweet)
      else
        raise TypeError.new("tweet must be a Hash but #{tweet.class}.")
      end
    end
  end

  #----------------------------------------------------------------------
  # EntitiesFromGem class
  #----------------------------------------------------------------------
  class EntitiesFromGem < Entities
    public_class_method :new

    def initialize(tweet)
      super()
      if tweet.entities? then
        # ハッシュタグ名と位置情報
        @hashtags      = Tw::Hashtags.new(tweet.attrs[:entities][:hashtags])
        # アタッチされたメディアのURLとか
        @media         = Tw::Media.new(tweet.attrs[:entities][:media])
        # $で始まる通貨シンボル情報
        @symbols       = Tw::Symbols.new(tweet.attrs[:entities][:symbols])
        # ツイートに含まれるURL情報の配列
        @urls          = Tw::TweetEntitiesUrls.new(tweet.attrs[:entities][:urls])
        # ツイート本文の文字列に含まれる @user の、ユーザ名ごとのインデックス
        @user_mentions = Tw::UserMentions.new(tweet.user_mentions)
      end
    end
  end

  #----------------------------------------------------------------------
  # EntitiesFromHash class
  #----------------------------------------------------------------------
  class EntitiesFromHash < Entities
    public_class_method :new

    def initialize(tweet)
      super()
      if tweet[:entities] then
        # ハッシュタグ名と位置情報
        @hashtags      = Tw::Hashtags.new(tweet[:entities][:hashtags])
        # アタッチされたメディアのURLとか
        @media         = Tw::Media.new(tweet[:entities][:media])
        # $で始まる通貨シンボル情報
        @symbols       = Tw::Symbols.new(tweet[:entities][:symbols])
        # ツイートに含まれるURL情報の配列
        @urls          = Tw::TweetEntitiesUrls.new(tweet[:entities][:urls])
        # ツイート本文の文字列に含まれる @user の、ユーザ名ごとのインデックス
        @user_mentions = Tw::UserMentions.new(tweet[:entities][:user_mentions])
      end
    end
  end

end
