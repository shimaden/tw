# encoding: UTF-8

module Tw

  #==================================================================
  # MentionsTimeline class
  # GET statuses/mentions_timeline
  # This method can only return up to 800 tweets.
  # https://dev.twitter.com/docs/api/1.1/get/statuses/mentions_timeline
  #==================================================================
  class MentionsTimeline < Timeline
    public_class_method :new

    END_POINT = '/1.1/statuses/mentions_timeline.json'

    MAX_COUNT_PER_REQUEST = 200
    #MAX_OBTAINABLE_TWEETS = 800
    MAX_OBTAINABLE_TWEETS = 800 * 1000

    #------------------------------------------------------------------------
    # Initialize
    #------------------------------------------------------------------------
    def initialize(requester, followers, reply_depth, options)
      super()
      if !options.has_key?(:count) then
        raise ArgumentError.new("#{bn(__FILE__)}(#{__LINE__})" \
          "options must have a :count parameter.")
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
    end

    protected

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
      # GET statuses/mentions_timeline
      options = {:tweet_mode => 'extended'}
      options.merge!(params[:opts])
      timeline = @requester.get(END_POINT, options)
      return timeline
    end

  end

end
