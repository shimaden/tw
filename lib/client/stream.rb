# encoding: UTF-8
# このファイルはＵＴＦ－８です。
 
require 'oauthclient'
require File.expand_path('stream_message', File.dirname(__FILE__))
require File.expand_path('../utility/mash_extension', File.dirname(__FILE__))

module Tw
  module Stream2; end
end

module Tw::Stream

  class Stream
    attr_reader :followersIds

    END_POINT          = 'https://userstream.twitter.com/1.1/user.json'
    END_POINT_FILTER   = 'https://stream.twitter.com/1.1/statuses/filter.json'
    OPTIONS_FOLLOWINGS = {'tweet_mode' => 'extended', 'with'  => 'followings'}.freeze
    #OPTIONS_TRACK      = {'tweet_mode' => 'extended', 'track' => nil}.freeze
    OPTIONS_FILTER     = {'tweet_mode' => 'extended'}.freeze
    HTTP_HEADER = {
      :default_header => {
        'Accept' => '*/*',
        'Accept-Encoding' => 'identity;q=1.0',
        #'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        #'Accept-Encoding' => 'gzip',
        'Connection' => 'Keep-Alive',
      }
    }

    def initialize(requester, followers_cache_option)
      @requester = requester
      @current_user_id = @requester.new_auth.user.id
      @followers_cache_option = followers_cache_option
      @followers_cache_option[:filename] = Tw::Conf.follower_ids_filename(@current_user_id)

      @auth_client = OAuthClient.new(HTTP_HEADER)
      @auth_client.oauth_config.signature_method = 'HMAC-SHA1'
      @auth_client.oauth_config.consumer_key     = @requester.new_auth.consumer.key
      @auth_client.oauth_config.consumer_secret  = @requester.new_auth.consumer.secret
      @auth_client.oauth_config.token            = @requester.new_auth.access_token.token
      @auth_client.oauth_config.secret           = @requester.new_auth.access_token.secret

      @followersIds = Tw::CacheableFollowersIds.new(
                              @requester,
                              @followers_cache_option[:filename],
                              @followers_cache_option[:permission],
                              @followers_cache_option[:interval])
      @followersIds.get_all_followers_ids()

      # List of users following
      @friendsArray = Tw::Stream::FriendsList.new()
    end


    #------------------------------------------------
    # User stream
    #------------------------------------------------
    def user_stream(&block)
      raise ArgumentError.new('block not given') unless block_given?
      options = OPTIONS_FOLLOWINGS.dup
      begin
        loop do
          recv_buf = ""
          @auth_client.request('GET', END_POINT, options) do |chunk|
            recv_buf << chunk
            # recv_buf から 1 行ずつ取り出して status に格納
            # （recv_buf は複数行格納している可能性もあるのでループで処理）
            while (json_line = recv_buf[/.+?(\r\n)+/m]) != nil do
              recv_buf[0..(json_line.size - 1)] = ""  # recv_buf の先頭の 1 行を消去
              json_line.strip!
              next if json_line.size < 2
              data = self.perform(json_line)
              if !!data then
                yield(data)
              end
            end
          end
        end
      rescue HTTPClient::ReceiveTimeoutError => e
        $stderr.puts("#{__FILE__}:#{__LINE__}: #{__method__}: #{e.class}: #{e.message}")
      end
    end

    #------------------------------------------------
    # Filter stream
    #------------------------------------------------
    def filter_stream(filter_options, friendsIds, is_include_retweets, &block)
      raise ArgumentError.new('block not given') unless block_given?

      @friendsArray.set(friendsIds)

      options = OPTIONS_FILTER.dup
      #users = [204245399, 17919393] # @nhk_news, @W7VOA
      #options['follow'] = users.join(',')
      users = nil
      if filter_options.has_key?(:follow) then
        options['follow'] = filter_options[:follow]
        users = options['follow'].split(',').map {|id| Integer(id)}
      end
      begin
        loop do
          recv_buf = ""
#$stderr.puts("options: #{options.inspect}")
#$stderr.puts("users: #{users.inspect}")
          @auth_client.request('POST', END_POINT_FILTER, options) do |chunk|
            recv_buf << chunk
            # recv_buf から 1 行ずつ取り出して status に格納
            # （recv_buf は複数行格納している可能性もあるのでループで処理）
            while (json_line = recv_buf[/.+?(\r\n)+/m]) != nil do
              recv_buf[0..(json_line.size - 1)] = ""  # recv_buf の先頭の 1 行を消去
              json_line.strip!
              next if json_line.size < 2
              data = self.perform(json_line)
              if !!data then
                if data.is_a?(Tw::Tweet) then
                  if options.has_key?('follow') then  # ユーザIDで検索している場合
#$stderr.puts("HERE 1: data.user.id: #{data.user.id}")
                    if users.include?(data.user.id) then
                      # 指定したユーザが投稿したTW
                      # 指定したユーザーのRT
                      yield(data)
                    else
#$stderr.puts("HERE 2: data.retweeted_status?: #{data.retweeted_status?}")
                      # 指定したユーザーへのリプライ（in_reply_to_status_idつき）
                      # 指定したユーザーのTWのRT
                      if data.retweeted_status? then
                        yield(data) if is_include_retweets
                      end
                      # 指定したユーザ宛の @リプライ
                    end
                    #if users.include?(data.user.id) then # 指定したユーザからのTW
                    #  yield(data)
                    #else  # 指定したユーザのTWを、誰かがRTしたもの
                    #  if is_include_retweets then
                    #    yield(data)
                    #  end
                    #end
                  else
                    yield(data)
                  end
                else
                  yield(data)
                end
              end
            end
          end
        end
      rescue HTTPClient::ReceiveTimeoutError => e
        $stderr.puts("#{__FILE__}:#{__LINE__}: #{__method__}: #{e.class}: #{e.message}")
      end
    end

    #------------------------------------------------
    # Home timeline (to salvage tweets while temporarily
    # disconected from the user stream)
    #------------------------------------------------
    def home_timeline(since_id)
      reply_depth = 0
      timeline_options = {
        :timeline_kind => :home,
        :count         => Tw::HomeTimeline::MAX_OBTAINABLE_TWEETS,
        :since_id      => since_id
      }
      home_timeline = Tw::Timeline.compose(@requester, @followers_cache_option, reply_depth, timeline_options)
      timeline = home_timeline.perform()
      return timeline.sort {|tw1, tw2| tw1.id <=> tw2.id}
    end

      #------------------------------------------------
    protected
      #------------------------------------------------

    #------------------------------------------------
    # Perform appropriate operation depends on object types
    #------------------------------------------------
    def perform(json_line)
      hash = JSON.parse(json_line, :symbolize_names => true)

      if hash[:friends] then
        # Friends list
        @friendsArray.set(hash)
        return hash
      elsif self.is_tweet?(hash) then
        # Tweet
        twTweet = self.hash_to_tweet(hash)
        return twTweet
      elsif hash[:direct_message] then
        # Direct message
        twDM = self.hash_to_dm(hash)
        return twDM
      else
        message = Tw::Stream::Message.create(hash)
        if message then
          return message
        else
          return hash
        end
      end
    end

    #------------------------------------------------
    # If chunk is a tweet, return true.
    #------------------------------------------------
    def is_tweet?(hash)
      return hash[:id] && hash[:user] && hash[:user][:screen_name] \
          && (hash[:text] || hash[:full_text]) && hash[:created_at]
    end

    #------------------------------------------------
    # If chunk is a DM, return true.
    #------------------------------------------------
    def is_direct_message?(hash)
      return hash[:sender] && hash[:recipient]
    end

    #------------------------------------------------
    # Convert hash into a Tw::Tweet
    #------------------------------------------------
    def hash_to_tweet(hash)
      hash[:user][:following]   = @friendsArray.following?(hash[:user][:id])
      hash[:user][:followed_by] = @followersIds.followed_by?(hash[:user][:id])
      if hash[:retweeted_status] && hash[:retweeted_status][:user] then
        rt_user_id = hash[:retweeted_status][:user][:id]
        hash[:retweeted_status][:user][:following] \
                              = @friendsArray.following?(rt_user_id)
        hash[:retweeted_status][:user][:followed_by] \
                              = @followersIds.followed_by?(rt_user_id)
      end
      twTweet = Tw::Tweet.compose(hash, @followersIds)
      return twTweet
    end

    #------------------------------------------------
    # Convert hash into a Tw::DMTweet
    #------------------------------------------------
    def hash_to_dm(hash)
      dm           = hash[:direct_message]
      sender       = dm[:sender]
      recipient    = dm[:recipient]
      sender_id    = sender[:id]
      recipient_id = recipient[:id]

      if sender_id == @current_user_id then
        direction = :sent
      elsif recipient_id == @current_user_id then
        direction = :received
      else
        direction = nil  # Inconsistent
      end

      followed_by_sender    = @followersIds.followed_by?(sender_id)
      sender[:following]    = @friendsArray.following?(sender_id)

      followed_by_recipient = @followersIds.followed_by?(recipient_id)
      recipient[:following] = @friendsArray.following?(recipient_id)

      twDM = Tw::DMTweet.compose(
                            dm,
                            direction,
                            followed_by_sender,
                            followed_by_recipient)
      return twDM
    end

  end

end
