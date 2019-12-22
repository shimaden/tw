# encoding: UTF-8
#
# API が 15 分間で使用できる回数
#             公式   3rdパーティ
# Home TL      180       15
# Mentions TL   60       15
# DM receive    60       15
# List TL      300      180
# Search       180      180
# http://gigazine.net/news/20130308-twitter-api-consumer-keys/

require 'json'
require 'net/http'
require 'net/http/post/multipart'
require File.expand_path('auth', File.dirname(__FILE__))
require File.expand_path('new_auth', File.dirname(__FILE__))
require File.expand_path('configuration', File.dirname(__FILE__))
require File.expand_path('twitter_requester', File.dirname(__FILE__))
require File.expand_path('single_tweet', File.dirname(__FILE__))
require File.expand_path('cacheable_friends_and_followers_ids', File.dirname(__FILE__))
require File.expand_path('timeline/timeline', File.dirname(__FILE__))
require File.expand_path('lists', File.dirname(__FILE__))
require File.expand_path('direct_messages', File.dirname(__FILE__))
require File.expand_path('apilimit', File.dirname(__FILE__))
require File.expand_path('blocks_ids_cursor', File.dirname(__FILE__))
require File.expand_path('mutes_ids_cursor', File.dirname(__FILE__))
require File.expand_path('retweeters_ids_cursor', File.dirname(__FILE__))
require File.expand_path('friends_ids_cursor', File.dirname(__FILE__))
require File.expand_path('followers_ids_cursor', File.dirname(__FILE__))
require File.expand_path('users_lookup', File.dirname(__FILE__))
require File.expand_path('container/tweet', File.dirname(__FILE__))

module Tw
  class Client
    attr_reader :client, :current_user_name, :current_user_id
    include Utility
    include Smdn::CGI

    # Base URL of APIs: https://api.twitter.com
    MEDIA_UPLOAD_URL = 'https://upload.twitter.com/1.1/media/upload.json'
    REVERSE_GEOCODE    = '/1.1/geo/reverse_geocode.json'
    STATUSES_SHOW      = '/1.1/statuses/show.json'
    STATUSES_UPDATE    = '/1.1/statuses/update.json'
    STATUSES_DESTROY   = '/1.1/statuses/destroy/:id.json'
    STATUSES_RETWEET   = '/1.1/statuses/retweet/:id.json'
    STATUSES_UNRETWEET = '/1.1/statuses/unretweet/:id.json'
    FAVORITES_CREATE   = '/1.1/favorites/create.json'
    FAVORITES_DESTROY  = '/1.1/favorites/destroy.json'
    DIRECT_MESSAGE_NEW = '/1.1/direct_messages/new.json'
    CONVERSATION_SHOW  = '/1.1/conversation/show/:id.json'
    ACTIVITY_ABOUT_ME  = '/1.1/activity/about_me.json'


    #-------------------------------------------------------
    # コンストラクタ
    #-------------------------------------------------------
    def initialize(followers_cache_options: {}, blocks_cache_options: {}, mutes_cache_options: {})
      @new_auth = nil  # Internal use.
      @current_user_name = nil
      @current_user_id   = nil
      @poster            = nil

      @followers_cache_permission = followers_cache_options[:permission]
      @followers_cache_interval   = followers_cache_options[:interval]

      blocks_cache_permission = blocks_cache_options[:permission]
      blocks_cache_interval   = blocks_cache_options[:interval]
      mutes_cache_permission  = mutes_cache_options[:permission]
      mutes_cache_interval    = mutes_cache_options[:interval]

      if @followers_cache_permission.nil? || @followers_cache_interval.nil? then
        raise ::ArgumentError.new("Invalid followers_cache_options values.")
      end
      if blocks_cache_permission.nil? || blocks_cache_interval.nil? then
        raise ::ArgumentError.new("Invalid blocks_cache_options values.")
      end
      if mutes_cache_permission.nil? || mutes_cache_interval.nil? then
        raise ::ArgumentError.new("Invalid mutes_cache_options values.")
      end
    end

    #-------------------------------------------------------
    # 新しい Twitter 認証
    #-------------------------------------------------------
    def new_auth(user = nil)  # Internal use.
      if @new_auth.nil? then  # Internal use.
        @new_auth = NewAuth.new(user) # Internal use.
        @new_auth.auth()  # Internal use.
        @current_user_name = @new_auth.screen_name # Internal use.
        @current_user_id   = @new_auth.user_id     # Internal use.
      end
      @requester ||= TwitterRequester.new(@new_auth) # Internal use.
      return @new_auth  # Internal use.
    end

    #-------------------------------------------------------
    # ツイッターに POST
    # I wonder what I should treat this method as.
    # options: Hash
    #-------------------------------------------------------
    def post__(endpoint, options, header = {})
      http_response = self.new_auth.access_token.post(endpoint, options, header) # Internal use.
      return http_response
    end

    #-------------------------------------------------------
    # ツイッターから GET
    # I wonder what I should treat this method as.
    # options: Hash
    #-------------------------------------------------------
    def get__(endpoint, options)
      path = endpoint + self.cgi_escape(options)
      http_response = self.new_auth.access_token.get(path) # Internal use.
      return http_response
     end

    #-------------------------------------------------------
    # Get Home Timeline
    # The same timeline on https://twitter.com/ .
    # count   : The number of tweets to get.
    # max_id  : Get a tweet specified with the max_id itself and older tweets 
    #           than the max_id, if specified.
    # since_id: Get newer tweets than the since_id from the latest tweet 
    #           toward the since_id, if specified. The since_id tweet itself 
    #           is not included.
    #           The value of since_id can be overritten with newer status id 
    #           by Twitter when specified since_id is too old for Twitter API.
    #-------------------------------------------------------
    def home_timeline(count, max_id, since_id, reply_depth)

      options = {
          :timeline_kind => :home,
          :count => count
      }
      options[:max_id  ] = max_id   if max_id
      options[:since_id] = since_id if since_id

      followers = self.followers()
      timeline = Tw::Timeline.compose(
                        @requester,
                        followers,
                        reply_depth,
                        options)
      tweetArray = timeline.perform()

      return tweetArray
    end

    #-------------------------------------------------------
    # Get Mentions Timeline
    # count   : The number of tweets to get.
    # max_id  : Get a tweet specified with the max_id itself and older tweets 
    #           than the max_id, if specified.
    # since_id: Get newer tweets than the since_id from the latest tweet 
    #           toward the since_id, if specified. The since_id tweet itself 
    #           is not included.
    #           The value of since_id can be overritten with newer status id 
    #           by Twitter when specified since_id is too old for Twitter API.
    #-------------------------------------------------------
    def mentions_timeline(count, max_id, since_id, reply_depth)

      options = {
          :timeline_kind => :mentions,
          :count => count
      }
      options[:max_id  ] = max_id   if max_id
      options[:since_id] = since_id if since_id

      followers = self.followers()
      timeline = Tw::Timeline.compose(
                        @requester,
                        followers,
                        reply_depth,
                        options)
      tweetArray = timeline.perform()

      return tweetArray
    end

    #-------------------------------------------------------
    # Get User Timeline
    # count   : The number of tweets to get.
    # max_id  : Get a tweet specified with the max_id itself and older tweets 
    #           than the max_id, if specified.
    # since_id: Get newer tweets than the since_id from the latest tweet 
    #           toward the since_id, if specified. The since_id tweet itself 
    #           is not included.
    #           The value of since_id can be overritten with newer status id 
    #           by Twitter when specified since_id is too old for Twitter API.
    #-------------------------------------------------------
    def user_timeline(user, count, max_id, since_id, reply_depth)

      options = {
          :timeline_kind => :user,
          :count => count
      }
      options[:user_id    ] = user if user.is_a?(Integer)
      options[:screen_name] = user if user.is_a?(String)
      options[:max_id     ] = max_id   if max_id
      options[:since_id   ] = since_id if since_id

      followers = self.followers()
      timeline = Tw::Timeline.compose(
                        @requester,
                        followers,
                        reply_depth,
                        options)
      tweetArray = timeline.perform()

      return tweetArray
    end

    #-------------------------------------------------------
    # Get Retweets_of_me Timeline
    # count   : The number of tweets to get.
    # max_id  : Get a tweet specified with the max_id itself and older tweets 
    #           than the max_id, if specified.
    # since_id: Get newer tweets than the since_id from the latest tweet 
    #           toward the since_id, if specified. The since_id tweet itself 
    #           is not included.
    #           The value of since_id can be overritten with newer status id 
    #           by Twitter when specified since_id is too old for Twitter API.
    #-------------------------------------------------------
    def retweets_of_me_timeline(count, max_id, since_id, reply_depth)

      options = {
          :timeline_kind => :retweets_of_me,
          :count => count
      }
      options[:max_id  ] = max_id   if max_id
      options[:since_id] = since_id if since_id

      followers = self.followers()
      timeline = Tw::Timeline.compose(
                        @requester,
                        followers,
                        reply_depth,
                        options)
      tweetArray = timeline.perform()

      return tweetArray
    end

    #-------------------------------------------------------
    # Get List Timeline
    # count   : The number of tweets to get.
    # max_id  : Get a tweet specified with the max_id itself and older tweets 
    #           than the max_id, if specified.
    # since_id: Get newer tweets than the since_id from the latest tweet 
    #           toward the since_id, if specified. The since_id tweet itself 
    #           is not included.
    #           The value of since_id can be overritten with newer status id 
    #           by Twitter when specified since_id is too old for Twitter API.
    #-------------------------------------------------------
    def list_timeline(username, listname, count, max_id, since_id, reply_depth)

      options = {
          :timeline_kind => :list,
          :screen_name   => username,
          :list_name     => listname,
          :count         => count
      }
      options[:max_id  ] = max_id   if max_id
      options[:since_id] = since_id if since_id

      followers = self.followers()
      timeline = Tw::Timeline.compose(
                        @requester,
                        followers,
                        reply_depth,
                        options)
      tweetArray = timeline.perform()

      return tweetArray
    end

    #-------------------------------------------------------
    # Get Search
    # count   : The number of tweets to get.
    # max_id  : Get a tweet specified with the max_id itself and older tweets 
    #           than the max_id, if specified.
    # since_id: Get newer tweets than the since_id from the latest tweet 
    #           toward the since_id, if specified. The since_id tweet itself 
    #           is not included.
    #           The value of since_id can be overritten with newer status id 
    #           by Twitter when specified since_id is too old for Twitter API.
    #-------------------------------------------------------
    def search_timeline(query, count, max_id, since_id, reply_depth)

      options = {
          :timeline_kind => :search,
          :q             => query[:q],
          :count         => count
      }
      options[:until      ] = query[:until]  if !!query[:until]
      options[:max_id     ] = max_id         if max_id
      options[:since_id   ] = since_id       if since_id
      options[:lang       ] = query[:lang]        if !!query[:lang]
      options[:locale     ] = query[:locale]      if !!query[:locale]
      options[:result_type] = query[:result_type] if !!query[:result_type]
      options[:include_entities] = true

      followers = self.followers()
      timeline = Tw::Timeline.compose(
                        @requester,
                        followers,
                        reply_depth,
                        options)
      tweetArray = timeline.perform()

      return tweetArray
    end

    #-------------------------------------------------------
    # Get Favorites Timeline
    # count   : The number of tweets to get.
    # max_id  : Get a tweet specified with the max_id itself and older tweets 
    #           than the max_id, if specified.
    # since_id: Get newer tweets than the since_id from the latest tweet 
    #           toward the since_id, if specified. The since_id tweet itself 
    #           is not included.
    #           The value of since_id can be overritten with newer status id 
    #           by Twitter when specified since_id is too old for Twitter API.
    #-------------------------------------------------------
    def favorites_timeline(user, count, max_id, since_id, reply_depth)

      options = {
          :timeline_kind => :favorites,
          :count => count
      }
      options[:user_id    ] = user if user.is_a?(Integer)
      options[:screen_name] = user if user.is_a?(String)
      options[:max_id     ] = max_id   if max_id
      options[:since_id   ] = since_id if since_id

      followers = self.followers()
      timeline = Tw::Timeline.compose(
                        @requester,
                        followers,
                        reply_depth,
                        options)
      tweetArray = timeline.perform()

      return tweetArray
    end

    #-------------------------------------------------------
    # List of the lists the specified user is subscribing.
    # 指定したユーザーが所有する（作った）リストの一覧
    #-------------------------------------------------------
    def lists_ownerships(user, list)
      lists_ownership = Tw::ListsOwnership.new(@requester, user)
      lists_ownership.perform()
      lists = lists_ownership.get()
      return lists, lists_ownership.exception
    end

    #-------------------------------------------------------
    # List of the lists the specified user is subscribed.
    # 指定したユーザーがメンバーになっているリストの一覧
    #-------------------------------------------------------
    def lists_memberships(user, list)
      lists_subscriptions = Tw::ListsMemberships.new(@requester, user)
      lists_subscriptions.perform()
      lists = lists_subscriptions.get()
      return lists, lists_subscriptions.exception
    end

    #-------------------------------------------------------
    # Returns the members of the specified list.
    # リストのメンバーになっているユーザーの一覧を返す。
    #-------------------------------------------------------
    def lists_members(options)
      followers = self.followers()

      list_members = Tw::ListsMembers.new(@requester, followers, options)
      users = list_members.get()
      return [users, followers.last_update_time]
    end

    #-------------------------------------------------------
    # リストにメンバーを加える（1人だけバージョン）
    #-------------------------------------------------------
    def lists_members_create(list, user, owner)
      followers = self.followers()
      lists_members_create = ListsMembersCreate.new(@requester, followers, list, user, owner)
      result = lists_members_create.perform()
      return result
    end

    #-------------------------------------------------------
    # リストからメンバーを外す（1人だけバージョン）
    #-------------------------------------------------------
    def lists_members_destroy(list, user, owner)
      followers = self.followers()
      lists_members_create = ListsMembersDestroy.new(@requester, followers, list, user, owner)
      result = lists_members_create.perform()
      return result
    end


    #-------------------------------------------------------
    # ダイレクト・メッセージ取得（自分宛）
    # GET direct_messages
    # https://dev.twitter.com/docs/api/1.1/get/direct_messages
    #-------------------------------------------------------
    def direct_messages_received(count)
      dm = Tw::ReceivedDirectMessages.new(@requester, self.followers())
      return dm.get_direct_messages(count)
    end

    #-------------------------------------------------------
    # ダイレクト・メッセージ取得（自分発）
    # GET direct_messages/sent
    # https://dev.twitter.com/docs/api/1.1/get/direct_messages/sent
    #-------------------------------------------------------
    def direct_messages_sent(count)
      dm = Tw::SentDirectMessages.new(@requester, self.followers)
      return dm.get_direct_messages(count)
    end

    #-------------------------------------------------------
    # Hash からツイートを 1 つ生成
    #-------------------------------------------------------
    def build_statuses(tweets)
      result = nil
      followers = self.followers()
      if block_given? then
        tweets.each do |hash|
          raise RuntimeError.new("Userは未対応です。") if hash.has_key?(:screen_name)
          tw = Tw::Tweet.compose(hash, followers)
          yield(tw)
        end
        result = nil
      else
        if tweets.is_a?(Array) then
          result = tweets.map{|hash| Tw::Tweet.compose(hash, followers)}
        else
          hash = tweets
          raise RuntimeError.new("Userは未対応です。") if hash.has_key?(:screen_name)
          result = Tw::Tweet.compose(hash, followers)
        end
      end
      return result
    end

    #-------------------------------------------------------
    # ツイートを 1 件読み込み
    # 例外
    #   Tw::Error::NotFound
    #-------------------------------------------------------
    def get_a_status(status_id, reply_depth, user_info)
      if !status_id.is_a?(Integer) then
        raise ::TypeError.new("status_id must be an Integer value but #{status_id.class}.")
      end

      opts = self.get_options_for_one_tweet()

      followers = self.followers()
      singleTweet = SingleTweet.new(@requester, followers)

      twTweet = singleTweet.get_a_tweet(status_id, user_info, opts)
      exceptions = singleTweet.exceptions
      # Get in-reply-to tweets if the twTweet has an in_status_reply_id.
      if twTweet.not_nil? && reply_depth > 0 then
        twTweet = singleTweet.chain_replies(
                      twTweet, reply_depth, opts)
      end

      return [twTweet, exceptions]
    end

    #-------------------------------------------------------
    # 会話を取得
    #-------------------------------------------------------
    def get_conversation(status_id)
      followers = self.followers()

      options = {:id => status_id, :trim_user => false, :tweet_mode => 'extended'}
      endpoint = CONVERSATION_SHOW.sub(/:id/, status_id.to_s)
      hash = @requester.get(endpoint, options)
      tweet_arr = hash.map{|tw| Tw::Tweet.compose(tw, followers)}
      return tweet_arr
    end

    #-------------------------------------------------------
    # 通知を取得
    #-------------------------------------------------------
    def get_activity_about_me(options)
      options_ = {
        #:cards_platform         => iPhone-12,
        :contributor_details    => 1,
        :count                  => 20,
        :filters                => nil,
        #:include_cards          => 1,
        :include_entities       => 1,
        :include_media_features => true,
        :include_my_retweet     => 1,
        :include_user_entities  => true,
        :latest_results         => true,
        :model_version          => 7,
        :since_id               => nil,
      }
      options_[:count]    = options[:count]    if options.has_key?(:count)
      options_[:since_id] = options[:since_id] if options.has_key?(:since_id)

      hash = @requester.get(ACTIVITY_ABOUT_ME, options_)
$stderr.puts("{\"activity\":" + hash.to_json + "}")
      return hash
    end

    #-------------------------------------------------------
    # Get the information of a specified user.
    # is_use_cache: フォロワー情報にキャッシュを使う
    #-------------------------------------------------------
    def get_user_info(user, is_use_cache: true)
      if !!is_use_cache then
        followers = self.followers()
        user_getter = Tw::UserGetter.new(@requester, followers)
        options = {:tweet_mode => 'extended', :include_entities => true}
        user = user_getter.users_show(user, options)
        last_update_time = followers.last_update_time
      else
        followers = nil
        user_getter = Tw::UserGetter.new(@requester, followers)
        options = {:tweet_mode => 'extended', :include_entities => true}
        user = user_getter.users_show(user, options)
        last_update_time = Time.now()
      end

      return [user, last_update_time]
    end

    #-------------------------------------------------------
    # ツイート送信
    # 例外
    #   Tw::Error::Forbidden
    #   Tw::Error::DuplicateStatus
    #   Tw::Error::AlreadyPosted   (obsolete?)
    #   Tw::Error::RequestTimeout
    #-------------------------------------------------------
    def tweet(message, options = {})
      options[:tweet_mode] = 'extended' if !options.has_key?(:tweet_mode)
      options[:status]     = message    if !options.has_key?(:status)
      json = @requester.post(STATUSES_UPDATE, options)
      return json
    end

    #-------------------------------------------------------
    # メディア（現在は写真）のアップロード
    # https://dev.twitter.com/rest/reference/post/media/upload
    # Supported image format: PNG, JPG, GIF, Animated GIF.
    #
    # file: Hash または File
    # 戻り値: media_id (Integer)
    #-------------------------------------------------------
    def upload_media(file, options)
      mime_type = 'application/octet-stream'
      fqdn = MEDIA_UPLOAD_URL
      uri = URI.parse(fqdn)
      params = {
          'media' => UploadIO.new(file, mime_type, 'image.img'),
      }
      params['additional_owners'] = options[:additional_owners] if !!options[:additional_owners]
      params['media_category']    = options[:media_category] if !!options[:media_category]
      req = Net::HTTP::Post::Multipart.new(uri.path, params)
      req['Accept-Encoding'] = 'identity'
      header = {}
      req.each_capitalized do |key, value|
        header[key.to_s] = value
      end
      body = nil
      if req.body_exist? then
        io = req.body_stream
        body = io.read
      end
      http_response = self.new_auth.access_token.post(fqdn, body, header) # Internal use.
      if !http_response.is_a?(Net::HTTPSuccess) then
        error = Tw::Error.create(http_response: http_response)
        raise error
      end
      hash = JSON.parse(http_response.body, :symbolize_names => true)
      media_id = hash[:media_id]
      return media_id
    end

    #-------------------------------------------------------
    # バイナリ・ファイルを直接アップロード
    #-------------------------------------------------------
    def upload_video_from_file(fqdn, file, options)
      # バイナリ・ファイルを直接アップロードするための
      # ヘッダとボディを Net::HTTP::Post::Multipart クラスを
      # 使って作成。結果は req オブジェクトに格納される。
      uri = URI.parse(fqdn)
      params = {
          'command'  => options[:command],
          'media_id' => options[:media_id],
          'media'    => UploadIO.new(file, 'video/media', 'fname.mp4'),
          'segment_index' => options[:segment_index]
      }
      req = Net::HTTP::Post::Multipart.new(uri.path, params)
      req['Accept-Encoding'] = 'identity'

      # req に作成されたヘッダとボディを
      # OAuth::AccessToken#post() で投稿できるようにデータを req
      # から header と body とに移す。
      header = {}
      req.each_capitalized do |key, value|
        header[key.to_s] = value
      end
      body = nil
      if req.body_exist? then
        io = req.body_stream
        body = io.read
      end
      http_response = self.new_auth.access_token.post(fqdn, body, header) # Internal use.
      return http_response
    end

    #-------------------------------------------------------
    # メディア（ビデオ）のアップロード INIT
    # https://dev.twitter.com/rest/public/uploading-media#chunkedupload
    # Supported image format:
    #     video/mp4 (.mp4), application/dash+xml (.mpd),
    #     application/x-mpegURL (.m3u8), video/webm (.webm)
    #
    # media_type: "video/mp4"
    # size      : size of video file
    # media_category: "tweet_image", "tweet_gif" (animated GIF only),
    #                 "tweet_video"
    # additional_owners:
    # 戻り値: {
    #           :media_id=>623731454128709632,
    #           :media_id_string=>"623731454128709632",
    #           :expires_after_secs=>3599
    #         }
    #-------------------------------------------------------
    def upload_video_init(media_type, size, media_category, additional_owners)
      options = {
        :command     => "INIT",
        :media_type  => media_type,
        :total_bytes => size,
      }
      options[:media_category]    = media_category    if !!media_category
      options[:additional_owners] = additional_owners if !!additional_owners
      http_response = self.post__(MEDIA_UPLOAD_URL, options)
      if !http_response.is_a?(Net::HTTPSuccess) then
        error = Tw::Error.create(video_upload_error: {:context => :init, :http_response => http_response})
        raise error
      end
      hash = JSON.parse(http_response.body, :symbolize_names => true)
      return hash
    end

    #-------------------------------------------------------
    # メディア（ビデオ）のアップロード APPEND
    #-------------------------------------------------------
    def upload_video_append(file, media_id, segment_index = 0)
      options = {
        :command       => "APPEND",
        :media_id      => media_id,
        :segment_index => segment_index,
      }

      http_response = self.upload_video_from_file(MEDIA_UPLOAD_URL, file, options)
      if !http_response.is_a?(Net::HTTPSuccess) then
        error = Tw::Error.create(
                    video_upload_error: {:context => :append, :http_response => http_response})
        raise error
      end
      if http_response.is_a?(Net::HTTPNoContent) then
        hash = nil
      else
        hash = JSON.parse(http_response.body, :symbolize_names => true)
      end
      return hash
    end

    #-------------------------------------------------------
    # メディア（ビデオ）のアップロード FINALIZE
    #-------------------------------------------------------
    def upload_video_finalize(media_id)
      options = {
        :command  => "FINALIZE",
        :media_id => media_id
      }

      http_response = self.post__(MEDIA_UPLOAD_URL, options)
      if !http_response.is_a?(Net::HTTPSuccess) then
        error = Tw::Error.create(video_upload_error: {:context => :finalize, :http_response => http_response})
        raise error
      end
      if http_response.is_a?(Net::HTTPNoContent) then
        result = nil
      else
        result = JSON.parse(http_response.body, :symbolize_names => true)
      end
      return result
    end

    #-------------------------------------------------------
    # メディア（ビデオ）のアップロードのポーリング STATUS
    #-------------------------------------------------------
    def upload_video_status(media_id)
      options = {
        :command  => "STATUS",
        :media_id => media_id
      }

      http_response = self.get__(MEDIA_UPLOAD_URL, options)
      if !http_response.is_a?(Net::HTTPSuccess) then
        error = Tw::Error.create(video_upload_error: {:context => :status, :http_response => http_response})
        raise error
      end
      result = JSON.parse(http_response.body, :symbolize_names => true)
      return result
    end

    #-------------------------------------------------------
    # ツイート削除
    # 例外
    #   Tw::Error::Unauthorized
    #-------------------------------------------------------
    def destroy_status(status_id, opts = {:trim_user => true})
      followers = self.followers()

      # Delete
      options = {:id => status_id, :trim_user => false}
      endpoint = STATUSES_DESTROY.sub(/:id/, status_id.to_s)
      hash = @requester.post(endpoint, options)
      user_id = hash[:user][:id]
      deleted_tweet = Tw::Tweet.compose(hash, followers)
      return deleted_tweet
    end

    #-------------------------------------------------------
    # リツイートする
    # Exception:
    #   Tw::Error::AlreadyRetweeted
    #   Tw::Error::Unauthorized
    #-------------------------------------------------------
    def retweet(status_id)
      followers = self.followers()

      # Retweet
      options = {:id => status_id, :trim_user => false}
      endpoint = STATUSES_RETWEET.sub(/:id/, status_id.to_s)
      hash = @requester.post(endpoint, options)
      if hash[:retweeted_status] then
        hash[:retweeted_status][:user][:followed_by] \
                = followers.followed_by?(hash[:retweeted_status][:user][:id])
      end
      reTweet = Tw::Tweet.compose(hash, followers)
      reTweet.result_of_retweet = true
      return reTweet
    end

    #-------------------------------------------------------
    # リツイート解除
    # 例外
    #   Tw::Error::Unauthorized
    #-------------------------------------------------------
    def unretweet(status_id, opts = {:trim_user => true})
      followers = self.followers()

      # Delete
      options = {:id => status_id, :trim_user => false}
      endpoint = STATUSES_UNRETWEET.sub(/:id/, status_id.to_s)
      hash = @requester.post(endpoint, options)
      user_id = hash[:user][:id]
      unretweet = Tw::Tweet.compose(hash, followers)
      return unretweet
    end

    #-------------------------------------------------------
    # お気に入りに追加
    #-------------------------------------------------------
    def favorite(status_id)
      followers = self.followers()

      # Favorite
      options = {:id => status_id, :include_entities => true}
      hash = @requester.post(FAVORITES_CREATE, options)
      user_id = hash[:user][:id]
      fav_tweet = Tw::Tweet.compose(hash, followers)
      return fav_tweet
    end

    #-------------------------------------------------------
    # お気に入りを取り消し
    #-------------------------------------------------------
    def unfavorite(status_id)
      followers = self.followers()

      # Unfavorite
      options = {:id => status_id, :include_entities => true}
      hash = @requester.post(FAVORITES_DESTROY, options)
      user_id = hash[:user][:id]
      unfav_tweet = Tw::Tweet.compose(hash, followers)
      return unfav_tweet
    end

    #-------------------------------------------------------
    # DM 送信
    #-------------------------------------------------------
    def create_direct_message(to_user, text, followers_cache_option)
      options = {}
      options[:user_id]     = to_user if to_user.is_a?(Integer)
      options[:screen_name] = to_user if to_user.is_a?(String)
      options[:text]        = text
      dm = @requester.post(DIRECT_MESSAGE_NEW, options)

      followers = self.followers()
      followed_by_sender    = false
      followed_by_recipient = followers.followed_by?(dm[:recipient][:id])
      direction = :sent
      twDM = Tw::DMTweet.compose(
                    dm, direction, followed_by_sender, followed_by_recipient)
    end

    #-------------------------------------------------------
    # ツイートをリツイートした人の ID リスト
    #-------------------------------------------------------
    def retweeters_ids(status_id)
      options = nil

      followers = self.followers()
      retweeters_list = Tw::RetweetersIDsCursor.new(@requester, status_id, options)
      users = retweeters_list.users()
      return users
    end

    #-------------------------------------------------------
    # ブロックしているユーザの ID リスト
    #-------------------------------------------------------
    def blocks_ids()
      options = nil

      followers = self.followers()
      blocks_list = Tw::BlocksIDsCursor.new(@requester, options)
      users = blocks_list.users()
      return users
    end

    #-------------------------------------------------------
    # ミュートしているユーザの ID リスト
    #-------------------------------------------------------
    def mutes_ids()
      options = nil

      followers = self.followers()
      mutes_list = Tw::MutesIDsCursor.new(@requester, options)
      users = mutes_list.users()
      return users
    end

    #-------------------------------------------------------
    # フォローしている人のユーザ ID
    #-------------------------------------------------------
    #def friends_ids(followers_cache_option, user)
    def friends_ids(user)
      options = nil

      friends_list = Tw::FriendsIDsCursor.new(@requester, user, options)
      user_ids = friends_list.users()
      return user_ids
    end

    #-------------------------------------------------------
    # フォロワーさんのユーザ ID
    #-------------------------------------------------------
    #def followers_ids(followers_cache_option, user)
    def followers_ids(user)
      options = nil

      followers_list = Tw::FollowersIDsCursor.new(@requester, user, options)
      user_ids = followers_list.users()
      return user_ids
    end

    #-------------------------------------------------------
    # フォロワーさんのユーザ ID 
    # （必要に応じてキャッシュから取る）
    #-------------------------------------------------------
    def followers_ids_from_cache()
      followers = self.followers()
      return followers
    end

    #-------------------------------------------------------
    # GET /users/lookup
    # Return value: Array of Tw::User objects.
    #-------------------------------------------------------
    def users_lookup(user_id_array, is_use_cache: true)
      users, last_update_time = self.users_lookup_ex(user_id_array, is_use_cache: is_use_cache)
      return users
    end

    #-------------------------------------------------------
    # GET /users/lookup
    # Return value: Array of Tw::User objects.
    #   users_array:
    #     lookup したいユーザの ID またはスクリーン・ネームの
    #     配列。
    #   is_use_cache:
    #     true : followed_by 情報をキャッシュから取得する。
    #     false: followed_by 情報を API からリアルタイムに取得する
    #-------------------------------------------------------
    def users_lookup_ex(users_array, is_use_cache: true)
      user_id_array = users_array.select {|u| u.is_a?(Integer)}
      screen_name_array = users_array.select {|u| u.is_a?(String)}

      lookedup_users = Tw::UsersLookup.new(@requester, user_id_array, screen_name_array)

      if !!is_use_cache then # キャッシュから followed_by 情報を付ける
        followers = self.followers()
        users = lookedup_users.users.map{|u| Tw::User.compose(u.attrs, followers.followed_by?(u.id))}
        last_update_time = followers.last_update_time
      else  # API から followed_by 情報を付加する
        followers = self.followers_ids(@current_user_id)
        users = lookedup_users.users.map{|u| Tw::User.compose(u.attrs, followers.include?(u.id))}
        last_update_time = Time.now()
      end

      return [users, last_update_time]
    end

    #-------------------------------------------------------
    # 位置情報を取得
    #-------------------------------------------------------
    def reverse_geocode(options = {})
      hash = @requester.get(REVERSE_GEOCODE ,options)
      return Tw::GeoResults.new(hash)
    end

    #-------------------------------------------------------
    # API 制限を取得するクラスのインスタンス
    #-------------------------------------------------------
    def apilimit()
      @apilimit ||= Tw::APILimit.new(@requester)
    end

    ##-------------------------------------------------------
    ## 本文全体の長さを weightened length を考慮して計算して
    ## 返す。この段階では本文中の URL は短縮扱いされず
    ## 他の文字列同様に扱われる。
    ##-------------------------------------------------------
    #
    #def weightened_message_length(message)
    #  @weightened_text ||= Tw::WeightenedText.new(Tw::Conf::CONF_WEIGHTENED_TEXT_FNAME)
    #  weightened_length = @weightened_text.length(message)
    #  return weightened_length
    #end

    ##-------------------------------------------------------
    ## 普通に数えた本文の長さ - 短縮URLで短縮された本文の長さ
    ## 短縮 URL によって短くなる本文の長さを返す。
    ##-------------------------------------------------------
    #def length_to_shorten_message(message, help_conf_opts)
    #  filename   = help_conf_opts[:filename]
    #  permission = help_conf_opts[:permission]
    #  interval   = help_conf_opts[:interval]
    #  @configuration ||= Configuration.new(
    #                        @requester, filename, permission, interval)
    #  length = @configuration.length_to_shorten_message(message)
    #  return length
    #end
    #-------------------------------------------------------
    # 普通に数えた本文の長さ - 短縮URLで短縮された本文の長さ
    # 短縮 URL によって短くなる本文の長さを返す。
    #-------------------------------------------------------
    def weightened_length_to_shorten_message(message, help_conf_opts)
      filename   = help_conf_opts[:filename]
      permission = help_conf_opts[:permission]
      interval   = help_conf_opts[:interval]
      @configuration ||= Configuration.new(
                            @requester, filename, permission, interval)
      length = @configuration.weightened_length_to_shorten_message(message)
      return length
    end

      #--------------------------------------------------------------------
    protected
      #--------------------------------------------------------------------

    #----------------------------------------------------------------
    # Tw::CacheableFollowersIds.new の followers_cache_option を返す。
    #----------------------------------------------------------------
    def followers()
      filename   = Tw::Conf.follower_ids_filename(@current_user_id)
      permission = @followers_cache_permission
      interval   = @followers_cache_interval

      followers  = Tw::CacheableFollowersIds.new(@requester, filename, permission, interval)
      followers.get_all_followers_ids()
      return followers
    end

    #-------------------------------------------------------
    # 1 ツイートの取得のためのオプションを得る
    # Need!
    #-------------------------------------------------------
    def get_options_for_one_tweet()
      return {
        :trim_user           => false,
        :include_rts         => true,
        :include_my_retweet  => true,
        :include_entities    => true,
        :contributor_details => true,
        :tweet_mode          => "extended",
        # The :exclude_replies is only supported for JSON and XML responses.
        :exclude_replies     => false,
      }
    end

  end

end
