# encoding: UTF-8
# 公式の説明
#   Tweets クラス https://dev.twitter.com/docs/platform-objects/tweets
#
require 'time'
require File.expand_path('user', File.dirname(__FILE__))
require File.expand_path('entities/entities_for_tweet', File.dirname(__FILE__))
require File.expand_path('extended_entities/extended_entities_for_tweet', File.dirname(__FILE__))
require File.expand_path('geo', File.dirname(__FILE__))
require File.expand_path('geo_results', File.dirname(__FILE__))
require File.expand_path('current_user_retweet', File.dirname(__FILE__))
require File.expand_path('card', File.dirname(__FILE__))
require File.expand_path('tweet_helper', File.dirname(__FILE__))
require File.expand_path('tweet_kind', File.dirname(__FILE__))

module Tw
  #----------------------------------------------------------------------
  # AbstractTweet クラス
  #----------------------------------------------------------------------
  class AbstractTweet
    private_class_method :new
    attr_reader :id, :text, :full_text, :truncated, :display_text_range,
                :created_at, :source, :user, :geo, :coordinates,
                :retweeted, :favorited, :retweet_count, :favorite_count,
                :possibly_sensitive, :coordinates, :place, :contributors,
                :in_reply_to_status_id, :in_reply_to_user_id,
                :in_reply_to_screen_name, :in_reply_to_status,
                :retweeted_status, :quoted_status, :current_user_retweet,
                :entities, :extended_entities, :kind, :card,
                :attrs
    attr_accessor :in_reply_to_status

    include TweetHelper

    def initialize()
      @new_140_count_feature = false

      @id             = nil
      @text           = nil
      @full_text      = nil
      @truncated      = nil
      @display_text_range = nil
      @created_at     = nil
      @source         = nil
      @user           = nil
      @geo            = nil
      @coordinates    = nil
      @retweeted      = nil
      @favorited      = nil
      @retweet_count  = nil
      @favorite_count = nil
      @possibly_sensitive = nil
      @place          = nil
      @contributors   = nil

      # in reply to
      @in_reply_to_status_id   = nil
      @in_reply_to_user_id     = nil
      @in_reply_to_screen_name = nil

      @in_reply_to_status      = nil

      @retweeted_status = nil
      @quoted_status    = nil

      @card = nil

      @current_user_retweet = nil

      @entities = nil

      @extended_entities = nil

      @result_of_retweet = nil

      @attrs   = nil
    end

    def new_140_count_feature?
      return @new_140_count_feature
    end

    def truncated?()
      return @truncated
    end

    def id?()
      return @id.not_nil?
    end

    def entities?()
      return @entities.not_nil?
    end

    def extended_entities?()
      return @extended_entities.not_nil?
    end

    def client
      /\<.*\>(.*)\</ =~ @source
      return ($1.nil?) ? @source : $1
    end

    def in_reply_to_status_id?
      return @in_reply_to_status_id.to_s =~ /^[0-9]+$/
    end

    def in_reply_to_status?
      return !@in_reply_to_status.nil?
    end

    def in_reply_to_url
      if self.in_reply_to_status_id? then
        return  "https://twitter.com/#{self.in_reply_to_screen_name}" \
                "/status/#{self.in_reply_to_status_id}"
      else
        return nil
      end
    end

    def url
      return "https://twitter.com/#{user.screen_name}/status/#{id}"
    end

    def to_s
      time = @created_at.strftime('%Y-%m-%d %H:%M')
      screen_name = @user.screen_name if !@user.nil?
      return "(#{time})@#{screen_name}> #{@text}"
    end

    def unreadable_tweet?
      return false
    end

    def retweeted_status?
      return @retweeted_status.not_nil?
    end

    def result_of_retweet?()
      return @result_of_retweet != nil
    end

    def result_of_retweet=(bool)
      @result_of_retweet = bool
    end

    def quoted_status?
      return @quoted_status != nil
    end

    def card?()
      return !!@card
    end

    def to_json(*a)
    end
  end

  #----------------------------------------------------------------------
  # Tweet クラス
  #   (Strategy pattern 的な何か。)
  #----------------------------------------------------------------------
  class Tweet < AbstractTweet
    private_class_method :new

    def initialize()
      super()
      @kind = TweetKind.new(self)
    end

    # Strategy pattern 的な何か
    # Tw::Tweet の（下位クラスの）インスタンスを返す。
    # tweet_or_user にどのような型のインスタンスが渡される
    # かにより、適切な下位クラスを作って返す。
    def self.compose(tweet, my_followers)
      return nil if tweet.nil?

      begin
        public_class_method(:new)
        if tweet.is_a?(::Hash) then
          twTweet = TweetFromHashTweet.new(tweet, my_followers)
        else
          raise TypeError.new("tweet must be a Hash but #{tweet.class}.")
        end
      ensure
        private_class_method(:new)
      end
      return twTweet
    end

  end

  #----------------------------------------------------------------------
  # TweetFromHashTweet クラス
  #----------------------------------------------------------------------
  class TweetFromHashTweet < Tweet
    private_class_method :new
    attr_reader :attrs

    def initialize(tweet, my_followers)
      super()
      if !tweet.is_a?(Hash) then
        raise TypeError.new(
          "\'tweet\' must be Hash but #{tweet.class}."
        )
      end

      if my_followers.is_a?(Tw::CacheableFriendsAndFollowersIds) then
        @followed_by = my_followers.followed_by?(tweet[:user][:id])
      else
        @followed_by = my_followers
      end

      @attrs = tweet

      @new_140_count_feature = tweet.has_key?(:display_text_range) \
                            && tweet.has_key?(:full_text) && !tweet.has_key?(:text)

      @id             = tweet[:id]
      @text           = @new_140_count_feature ? nil : tweet[:text]
      @full_text      = @new_140_count_feature ? tweet[:full_text] : nil
      @truncated      = tweet[:truncated]  # RTした時に140字に縮められたか
      @display_text_range = tweet[:display_text_range]
      @created_at     = Time.parse(tweet[:created_at])
      @source         = tweet[:source]     # 使用したクライアント
      @user           = Tw::User.compose(tweet[:user], @followed_by)
      if tweet[:geo] then
        @geo          = Geo.new(tweet[:geo])  # :coordinates フィールドを代わりに使え
      else
        @geo          = nil
      end
      @coordinates    = tweet[:coordinates] # 座標
      @retweeted      = tweet[:retweeted]  # 誰かにリツイートされているか
      @favorited      = tweet[:favorited]  # 誰かにふぁぼられているか
      @retweet_count  = tweet[:retweet_count]  # 何回リツイートされたか
      @favorite_count = tweet[:favorite_count] # 何回ふぁぼられたか
      @possibly_sensitive = tweet[:possibly_sensitive] # 不適切な内容か (*1)
        # ツイートされた場所の国名や座標など
      @place          = Tw::GeoResults::Place.new(tweet[:place]) if !!tweet[:place]
      @contributors   = tweet[:contributors]

      # in reply to
      @in_reply_to_status_id   = tweet[:in_reply_to_status_id]
      @in_reply_to_user_id     = tweet[:in_reply_to_user_id]
      @in_reply_to_screen_name = tweet[:in_reply_to_screen_name]

      # Tw::Tweet 型。リプライ先のツイートそのもの。
      @in_reply_to_status      = nil

      # リツイートである場合、そのオリジナル・ツイートそのもの。
      # 公式リツイートすると、このような構造になっている。
      # 通常のツイートの場合：
      # {
      #     ツイート内容
      # }
      # 公式リツイートの場合：
      # {
      #     ツイート内容
      #     retweeted_status
      #     {
      #         オリジナルのツイートの内容
      #     }
      # }
      if tweet[:retweeted_status] && tweet[:retweeted_status][:user] then
        @retweeted_status = Tw::Tweet.compose(tweet[:retweeted_status], my_followers)
      end
      if tweet[:quoted_status] && tweet[:quoted_status][:user] then
        @quoted_status = Tw::Tweet.compose(tweet[:quoted_status], my_followers)
      end

      @current_user_retweet = Tw::CurrentUserRetweet.compose(
                                    tweet[:current_user_retweet])
      @card = Tw::Card.new(tweet[:card]) if !!tweet[:card]

      @entities = Tw::Entities.compose(tweet)

      @extended_entities = Tw::ExtendedEntities.compose(tweet) if !!tweet[:extended_entities]

      # (*1) リンクを含む場合のみ。
    end

    def to_json(*a)
      hash = {}
      @attrs.each do |key, val|
        hash[key] = @attrs[key]
        if key == :in_reply_to_screen_name then
          hash[:in_reply_to_status] = @in_reply_to_status if self.in_reply_to_status?
        end
      end
      hash[:created_at]       = @created_at
      hash[:retweeted_status] = @retweeted_status if @attrs.has_key?(:retweeted_status)
      hash[:quoted_status]    = @quoted_status    if @attrs.has_key?(:quoted_status)
      hash[:user] = @user if !!@user
      hash[:card] = @card if !!@card
      return hash.to_json(*a)
    end
  end

  #----------------------------------------------------------------------
  # UnreadableTweet クラス
  # 鍵垢等の理由でツイートの内容は得られないが、ユーザ情報だけでも格納しようと
  # いう模擬の Tweet クラス。
  #----------------------------------------------------------------------
  class UnreadableTweet < Tweet
    public_class_method :new

    def initialize(id, twUser)
      super()

      @id             = id
      @text           = ""
      @full_text      = ""
      @truncated      = nil
      @display_text_range = nil
      @created_at     = nil
      @source         = ""
      @user           = twUser
      @geo            = nil
      @coordinates    = nil
      @retweeted      = nil
      @favorited      = nil
      @retweet_count  = nil
      @favorite_count = nil
      @possibly_sensitive = nil
      @place          = nil
      @contributors   = nil

      # in reply to
      @in_reply_to_status_id   = nil
      @in_reply_to_user_id     = nil
      @in_reply_to_screen_name = nil

      @in_reply_to_status      = nil

      @retweeted_status = nil
      @quoted_status = nil

      @current_user_retweet = nil

      @entities = nil

      @extended_entities = nil
    end

    def unreadable_tweet?
      return true
    end

    def to_json(*a)
      hash = {
        :id     => @id,
        :id_str => @id.to_s,
        :user   => @user,
      }
      return hash.to_json(*a)
    end
  end

end
