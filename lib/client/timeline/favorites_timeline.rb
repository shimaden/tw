module Tw

  #==================================================================
  # FavoritesTimeline class
  # GET statuses/user_timeline
  # This method can only return up to 3,200 of a user's most recent Tweets.
  # https://dev.twitter.com/rest/reference/get/favorites/list
  #==================================================================
  class FavoritesTimeline < Timeline
    public_class_method :new

    END_POINT = '/1.1/favorites/list.json'

    MAX_COUNT_PER_REQUEST =  200
    MAX_OBTAINABLE_TWEETS = 3200  # Undocumented value.

    #------------------------------------------------------------------------
    # Initialize
    #------------------------------------------------------------------------
    def initialize(requester, followers, reply_depth, options)
      super()
      if !options.has_key?(:count) then
        raise ArgumentError.new("#{bn(__FILE__)}(#{__LINE__})" \
          "options must have a :count parameter.")
      end
      if !(options.has_key?(:screen_name) || options.has_key?(:user_id)) then
        raise ArgumentError.new("#{bn(__FILE__)}(#{__LINE__})" \
          "options must have a :screen_name parameter.")
      end
      opts = options.clone()
      if opts[:count] > MAX_OBTAINABLE_TWEETS then
        opts[:count] = MAX_OBTAINABLE_TWEETS
      end
      @requester   = requester
      @followers   = followers
      @reply_depth = reply_depth
      @options     = opts
      @count       = opts[:count]
      @user_id     = opts[:user_id]
      @username    = opts[:screen_name]
    end

    protected

    #------------------------------------------------------------------------
    # 引数で指定されたユーザの情報を取得し、そのユーザの
    # お気に入りリスト（ツイート）が取得できるかを調べる。
    #
    # 鍵がかかっているユーザの場合、お気に入りリストを
    # 読まずにリターンする。
    # この場合、Tw::Tweet 型を要素とする、要素数 1 の
    # 配列が返される。
    #------------------------------------------------------------------------
    def doPreprocess(followersIds)
      userGetter = Tw::UserGetter.new(@requester, followersIds)
      user = @user_id ? @user_id : @username
      twUser = userGetter.users_show(user,
                    {:include_entities => false, :skip_status => true})
      if !twUser.tweet_accessible? then
        status_id = nil
        tweetArray = [Tw::UnreadableTweet.new(status_id, twUser)]
        return tweetArray
      else
        return nil
      end
    end

    #------------------------------------------------------------------------
    # Return a maximum number of gettable tweets per a request.
    #------------------------------------------------------------------------
    def doGetMaxCountPerRequest()
      return MAX_COUNT_PER_REQUEST
    end

    #------------------------------------------------------------------------
    # Return a maximum number of obtainable tweets.
    #------------------------------------------------------------------------
    def doGetMaxObtainableTweets()
      return MAX_OBTAINABLE_TWEETS
    end

    #------------------------------------------------------------------------
    # タイムラインを取得する。
    #------------------------------------------------------------------------
    def doGetTimelineTweetArray(obsolete, params)
      # GET favorites/list
      options = {:tweet_mode => 'extended'}
      options[:user_id]     = params[:user] if params[:user].is_a?(Integer)
      options[:screen_name] = params[:user] if params[:user].is_a?(String)
      options.merge!(params[:opts])
      timeline = @requester.get(END_POINT, options)
      return timeline
    end
  end

end
