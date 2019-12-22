# encoding: UTF-8

module Tw

  #==================================================================
  # DirectMessagesTimeline class
  # Returns all Direct Message events (both sent and received) 
  # within the last 30 days. Sorted in reverse-chronological order.
  # GET direct_messages/events/list
  # https://api.twitter.com/1.1/direct_messages/events/list.json
  #==================================================================
  class DirectMessagesTimeline < Timeline
    public_class_method :new

    END_POINT = '/1.1/direct_messages/events/list.json'

    MAX_COUNT_PER_REQUEST = 100
    MAX_OBTAINABLE_TWEETS = 100

    #------------------------------------------------------------------------
    # Initialize
    #------------------------------------------------------------------------
    def initialize(requester, followers, options)
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
      #@reply_depth = reply_depth
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
      options.merge!(params[:opts])
      timeline = @requester.get(END_POINT, options)
      return timeline
    end

  end

end
