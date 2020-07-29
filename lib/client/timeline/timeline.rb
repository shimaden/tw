# encoding: UTF-8
require File.expand_path('../user_getter', File.dirname(__FILE__))
require File.expand_path('../single_tweet', File.dirname(__FILE__))
require File.expand_path('../../utility/cgi_escape', File.dirname(__FILE__))

module Tw
  class Timeline
  end
end

require File.expand_path('home_timeline', File.dirname(__FILE__))
require File.expand_path('mentions_timeline', File.dirname(__FILE__))
require File.expand_path('user_timeline', File.dirname(__FILE__))
require File.expand_path('retweets_of_me_timeline', File.dirname(__FILE__))
require File.expand_path('search_timeline', File.dirname(__FILE__))
require File.expand_path('lists_statuses_timeline', File.dirname(__FILE__))
require File.expand_path('favorites_timeline', File.dirname(__FILE__))

include Utility

module Tw

  #==================================================================
  # Timeline class
  #==================================================================
  class Timeline
#    private_class_method :new
    attr_reader :max_id, :oldest_id

    include Smdn::CGI

    #------------------------------------------------------------------------
    # Initialiser
    #------------------------------------------------------------------------
    def initialize()
      @max_id    = nil
      @oldest_id = nil
    end

    protected

    #------------------------------------------------------------------------
    # フォロワーの配列を返す。
    #------------------------------------------------------------------------
    def followers()
      return @followers
    end

    public

    #------------------------------------------------------------------------
    # インスタンスを作成
    #   requester:
    #       Tw::TwitterRequester
    #   followers:
    #       フォロワーの ID を取得したりキャッシュに蓄えたりする
    #       クラス用のオプション。
    #   options: Hash
    #       :timeline_kind : "home", "user" or "mentions"
    #------------------------------------------------------------------------
    def self.compose(requester, followers, reply_depth, options)

      if not options.has_key?(:timeline_kind) then
        raise ArgumentError.new("In #{bn(__FILE__)}(#{(__LINE__)}): " \
            "options must has a ':timeline_kind' key.")
      end

      if options[:timeline_kind] == :home then
        tl = Tw::HomeTimeline.new(
                        requester,
                        followers,
                        reply_depth,
                        options)
      elsif options[:timeline_kind] == :mentions then
        tl = Tw::MentionsTimeline.new(
                        requester,
                        followers,
                        reply_depth,
                        options)
      elsif options[:timeline_kind] == :user then
        if options.has_key?(:screen_name) || options.has_key?(:user_id) then
          tl = Tw::UserTimeline.new(
                        requester,
                        followers,
                        reply_depth,
                        options)
        else
          raise ArgumentError.new("In #{bn(__FILE__)}(#{(__LINE__)}): " \
             "A :screen_name or a :user_id must be specified in the options " \
             "parameter when requesting user timeline.")
        end
      elsif options[:timeline_kind] == :retweets_of_me then
        tl = Tw::RetweetsOfMeTimeline.new(
                        requester,
                        followers,
                        reply_depth,
                        options)

      elsif options[:timeline_kind] == :list then
        tl = Tw::ListsStatusesTimeline.new(
                        requester,
                        followers,
                        reply_depth,
                        options)
      elsif options[:timeline_kind] == :search then
        tl = Tw::SearchTimeline.new(
                        requester,
                        followers,
                        reply_depth,
                        options)
      elsif options[:timeline_kind] == :search_universal then
        tl = Tw::SearchUniversalTimeline.new(
                        requester,
                        followers,
                        reply_depth,
                        options)
      elsif options[:timeline_kind] == :favorites then
        if options.has_key?(:screen_name) || options.has_key?(:user_id) then
          tl = Tw::FavoritesTimeline.new(
                        requester,
                        followers,
                        reply_depth,
                        options)
        else
          raise ArgumentError.new("In #{bn(__FILE__)}(#{(__LINE__)}): " \
             "A :screen_name or a :user_id must be specified in the options " \
             "parameter when requesting favorites timeline.")
        end
      else
        raise ArgumentError.new("In #{bn(__FILE__)}(#{(__LINE__)}): " \
            "Unsupported :timeline_kind '#{options[:timeline_kind].to_s}\.'")
      end

      return tl
    end

    #------------------------------------------------------------------------
    # タイムラインを取得する。
    #------------------------------------------------------------------------
    def perform()
      opts = self.get_options_for_timeline()

      if @options[:max_id] then
        opts[:max_id] = @options[:max_id]
      end
      if @options[:since_id] then
        opts[:since_id] = @options[:since_id]
      end

      if opts[:max_id] && opts[:since_id] then
        if opts[:max_id] <= opts[:since_id] then
          raise RangeError.new(blderr(__FILE__, __LINE__,
            ":max_id must be greater than :since_id"))
        end
      end

      followersIds = self.followers()

      tweetArray = self.doPreprocess(followersIds)
      if tweetArray.not_nil? then
        return tweetArray
      end

      singleTweet = SingleTweet.new(@requester, followersIds)

      isFirst   = true
      oldest_id = nil
      latest_id = nil

      # request_counter: 何回目のリクエストか
      request_counter = 1

      if @options[:count_unlimited] then
        request_times = doGetMaxObtainableTweets() / doGetMaxCountPerRequest()
        count_mod     = 0
        first_count   = doGetMaxCountPerRequest()
        opts[:count]  = doGetMaxCountPerRequest()
      else
        # request_times: リクエスト回数
        # count_mod    : 最後のリクエスト時にセットするカウント（割り算の商）
        # first_count  : count が self.doGetMaxCountPerRequest() 未満の
        #                時に 1 回目のリクエストで要求するカウント
        request_times, count_mod, first_count = self.how_many_times(@count)
        opts[:count] = first_count
      end

      tweetArray = Array.new

      #---------------------------------------------------------------
      # Main loop:
      # In the following loop, get tweets up to the maximum request number
      # given from the self.doGetMaxCountPerRequest() in each repetition.
      #---------------------------------------------------------------
      is_quit = false
      while request_counter <= request_times && !is_quit do

        if request_counter == request_times then
          if count_mod > 0 then
              opts[:count] = count_mod
          end
        end

        # Get tweet Array from timeline here.
        params = {}
        if @user_id || @username then
          params[:user] = @user_id ? @user_id : @username
        end
        if !!@listname then
          params[:listname] = @listname
        end
        if !!@query then
          params[:q] = @query
        end
        params[:opts] = opts
        not_used = nil
        timeline = self.doGetTimelineTweetArray(not_used, params)

        #-------------------------------------------------------
        # Reply collection loop:
        # Get in-reply-to tweets for each tweet in the timeline.
        #-------------------------------------------------------
        if timeline.size > 0 then
          timeline.map do |tweet|
            # In this loop, process tweets in the timeline Array one bye one.
            if tweet.is_a?(Hash) then
              tw = Tw::Tweet.compose(tweet, followersIds)
            else
              raise ::TypeError.new("tweet must be a Hash but #{tweet.class}.")
            end

            # If the Tw::Tweet object (tw) has an in_reply_to_status_id,
            # get the tweet indicated by the in_reply_to_status_id and add it
            # to the in_reply_to_status attribute of the original Tw::Tweet.
            # This process is performed recursively until a tweet does not
            # have an in_reply_to_status_id is found.
            singleTweet.chain_replies(tw, @reply_depth, opts)
            tweetArray.push(tw)
            if isFirst then
              latest_id = tw.id
              isFirst = false
            end
            oldest_id = tw.id
          end

          @oldest_id = oldest_id
          @max_id    = oldest_id - 1
          opts[:max_id] = oldest_id - 1
        else
          is_quit = true
        end
        #-------------------------------------------------------
        # End of recply colloction loop.
        #-------------------------------------------------------

        request_counter += 1
      end
      #---------------------------------------------------------------
      # End of main loop.
      #---------------------------------------------------------------

      return self.sort(tweetArray)
    end

    protected

    #------------------------------------------------------------------------
    # A Template Method
    # Do not implelment this here but sub classes.
    #------------------------------------------------------------------------
    def doPreprocess(followersIds)
    end

    #------------------------------------------------------------------------
    # A Template Method
    # Do not implelment this here but sub classes.
    #------------------------------------------------------------------------
    def doGetTimelineTweetArray(obsolete, params)
    end

    #------------------------------------------------------------------------
    # A Template Method
    # Do not implelment this here but sub classes.
    #------------------------------------------------------------------------
    def doGetMaxCountPerRequest()
    end

    #------------------------------------------------------------------------
    # 以下の timeline を呼び出す時に使用するオプションを返す。
    # statuses/home_timeline
    # statuses/mentions_timeline
    # statuses/retweets_of_me
    # statuses/user_timeline
    #------------------------------------------------------------------------
    def get_options_for_timeline()
      options = {
        :count                 => nil,
        :trim_user             => false,
        :include_rts           => true,
        :include_my_retweet    => true,
        :include_entities      => true,
        #:include_rts           => true,
        :contributor_details   => true,
        :include_user_entities => true,
        # The :exclude_replies is only supported for JSON and XML responses.
        :exclude_replies       => false,
      }
      options[:include_cards]  = @options[:include_cards]  if @options.has_key?(:include_cards)
      options[:cards_platform] = @options[:cards_platform] if @options.has_key?(:cards_platform)
      return options
    end

    #------------------------------------------------------------------------
    # timeline を呼び出す回数を取得する
    #------------------------------------------------------------------------
    def how_many_times(count)
      max_count_per_request = self.doGetMaxCountPerRequest()
      # request_times: リクエスト回数
      request_times, count_mod = count.divmod(max_count_per_request)
      if count_mod > 0 then
        request_times += 1
      end
      if request_times <= 1 then
        first_count = count
      else
        first_count = max_count_per_request
      end

      return request_times, count_mod, first_count
    end

    #----------------------------------------------------------------
    # Sort result.
    #----------------------------------------------------------------
    def sort(timeline)
      sorted = timeline.sort do |tweet1, tweet2|
        tweet1.id <=> tweet2.id
      end
      return sorted
    end

  end

end
