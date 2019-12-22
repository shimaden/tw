module Tw

  #==================================================================
  # SearchTimeline class
  # GET search/tweets
  # This method can only return up to 3,200 of a user's most recent Tweets.
  # https://dev.twitter.com/rest/reference/get/search/tweets
  #==================================================================
  class SearchTimeline < Timeline
    attr_reader :search_metadata
    public_class_method :new

    END_POINT = '/1.1/search/tweets.json'

    MAX_COUNT_PER_REQUEST =  100
    #MAX_OBTAINABLE_TWEETS = 3200
    MAX_OBTAINABLE_TWEETS = 3200 * 10

    #------------------------------------------------------------------------
    # Initialize
    #------------------------------------------------------------------------
    def initialize(requester, followers, reply_depth, options)
      super()
      if !options.has_key?(:count) then
        raise ArgumentError.new("#{bn(__FILE__)}(#{__LINE__})" \
          "options must have a :count parameter.")
      end
      if !(options.has_key?(:q)) then
        raise ArgumentError.new("#{bn(__FILE__)}(#{__LINE__})" \
          "options must have a :q parameter.")
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
      # GET search/tweets
      opts = params[:opts]

      options = {:tweet_mode => 'extended'}
      options[:q]           = @options[:q]
      options[:lang]        = opts[:lang]        if !!opts[:lang]
      options[:locale]      = opts[:locale]      if !!opts[:locale]
      options[:result_type] = opts[:result_type] if !!opts[:result_type]
      options[:result_type] = @options[:result_type] if !!@options[:result_type]
      options[:count]       = opts[:count]       if !!opts[:count]
      options[:since_id]    = opts[:since_id]    if !!opts[:since_id]
      options[:max_id]      = opts[:max_id]      if !!opts[:max_id]

      search_result = @requester.get(END_POINT, options)
      @search_metadata = search_result[:search_metadata]
      timeline         = search_result[:statuses]

      return timeline
    end
  end

end
