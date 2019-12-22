# encoding: UTF-8

module Tw

  #==================================================================
  # ListsStatusesTimeline class
  # GET lists/statuses
  # It is undocumented how many Tweets can be gotten.
  # https://dev.twitter.com/rest/reference/get/lists/statuses
  #==================================================================
  class ListsStatusesTimeline < Timeline
    public_class_method :new

    END_POINT = '/1.1/lists/statuses.json'

    # These are provisional values.
    MAX_COUNT_PER_REQUEST = 200
    #MAX_OBTAINABLE_TWEETS = 800
    MAX_OBTAINABLE_TWEETS = 800 * 100

    #------------------------------------------------------------------------
    # Initialize
    #------------------------------------------------------------------------
    def initialize(requester, followers, reply_depth, options)
      super()
      if !options.has_key?(:count) then
        raise ArgumentError.new("#{bn(__FILE__)}(#{__LINE__})" \
          "options must have a :count parameter.")
      end
      if !options.has_key?(:screen_name) then
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
      @username    = opts[:screen_name]
      @listname    = opts[:list_name]
    end

    protected

    #------------------------------------------------------------------------
    # 引数で指定されたユーザの情報を取得し、そのユーザの
    # リストのタイムライン（ツイート）が取得できるかを調べる。
    #
    # 鍵がかかっているユーザの場合、ユーザのリストのタイムラインを
    # 読まずにリターンする。
    # この場合、Tw::Tweet 型を要素とする、要素数 1 の
    # 配列が返される。
    #------------------------------------------------------------------------
    def doPreprocess(followersIds)
      userGetter = Tw::UserGetter.new(@requester, followersIds)
      twUser = userGetter.users_show(@username,
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
      # GET lists/statuses
      options = {:tweet_mode => 'extended'}
      options[:owner_id]          = params[:user] if params[:user].is_a?(Integer)
      options[:owner_screen_name] = params[:user] if params[:user].is_a?(String)
      options[:slug]              = params[:listname]
      options.merge!(params[:opts])
      timeline = @requester.get(END_POINT, options)
      return timeline
    end

  end

end
