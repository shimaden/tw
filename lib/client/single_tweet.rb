# encoding: UTF-8
require File.expand_path('../utility/cgi_escape', File.dirname(__FILE__))
require File.expand_path('error', File.dirname(__FILE__))

module Tw

  #----------------------------------------------------------
  # ツイート 1 つ単位でアクセスするクラス。
  #----------------------------------------------------------
  class SingleTweet
    attr_reader :exceptions
    include ::Smdn::CGI

    END_POINT = '/1.1/statuses/show.json'

    #-------------------------------------------------------
    # Initializer
    #-------------------------------------------------------
    def initialize(requester, followersIds)
      @requester = requester
      if !followersIds.is_a?(Tw::CacheableFollowersIds) then
        raise TypeError.new("In #{bn(__FILE__)}(#{__LINE__}): followersIds " \
                "must be Tw::Client class but #{followersIds.class} is given.")
      end
      @followersIds = followersIds
      @exceptions = []
    end

    protected

    #-------------------------------------------------------
    # This method returns a UserGetter object
    #-------------------------------------------------------
    def user_getter()
      @user_getter__ ||= UserGetter.new(@requester, @followersIds)
      return @user_getter__
    end

    #-------------------------------------------------------
    # user_info: ユーザID or スクリーン・ネーム
    #-------------------------------------------------------
    def get_unreadable_tweet(status_id, user_info)
      options = {:include_entities => true}
      user = self.user_getter.users_show(user_info, options)
      unreadable_tweet = Tw::UnreadableTweet.new(status_id, user)
      return unreadable_tweet
    end

    public

    #-------------------------------------------------------
    # ツイートを 1 つ Twitter から取得する。 
    #
    # 戻り値
    #   Tw::Tweet 型の下位クラス
    #     Tw::UnreadableTweet: status_id で指定されたツイートが
    #         鍵垢等で取得できなかった場合、user_info が
    #         指定されていた場合、可能であれば、
    #         Tw::UnreadableTweet オブジェクトを返す。
    #         このとき、
    #           Tw::UnreadableTweet#id   == status_id
    #           Tw::UnreadableTweet#user == user_info で指定された
    #                                       ユーザの情報。
    #   nil: status_id で指定されたツイートが取得できず、かつ
    #        user_info に nil が指定されていた場合。
    #
    # 引数
    #   status_id: 取得するツイートの status id。
    #   user_info: 取得しようとするツイートを送信した
    #              ユーザの user id、screen_name または nil。
    #
    # 例外
    #   Tw::Error::NotFound: When the tweet was not found.
    #-------------------------------------------------------
    def get_a_tweet(status_id, user_info, opts)
      if !status_id.is_a?(Integer) then
        raise ::TypeError.new("status_id must be an Integer value but #{status_id.class}.")
      end
      tweet = nil
      begin
        opts[:id] = status_id
        status = @requester.get(END_POINT, opts)
        tweet = Tw::Tweet.compose(status, @followersIds)
      rescue Tw::Error::Forbidden => e # 鍵垢等でツイートの取得が許可されないとき。
        # せめてユーザ情報ぐらいは持ってくる。
        @exceptions.push(e)
        if !!user_info then
          tweet = self.get_unreadable_tweet(status_id, user_info)
        end
      end
      return tweet
    end

    #-------------------------------------------------------
    # 与えられたツイートに in_reply_to_status_id が存在すれば、数珠つなぎに
    # 取得するメソッド。
    # 説明:
    #     Tw::Tweet 型の取得済みのツイート twTweet に in_reply_to_status_id が
    #     存在すれば、それを status id とするツイートを取得して、元の
    #     Tw::Tweet の in_reply_to_status につなぐ。つながれたツイートにも
    #     in_reply_to_status_id があれば、さらに取得してチェーン状につなぐ。
    #     in_reply_to_status_id が nil なツイートにあたるなるまで続けられる。
    #-------------------------------------------------------
    def chain_replies(tweet, depth, opts)
      counter = 0
      tw = tweet
      excep = nil
      is_quit = false
      while tw.in_reply_to_status_id? && counter < depth && !is_quit do
        begin
          tw.in_reply_to_status, excep = self.get_a_tweet(
                        tw.in_reply_to_status_id,
                        tw.in_reply_to_user_id,
                        opts)
          break if tw.in_reply_to_status.nil?
          tw = tw.in_reply_to_status
          @exceptions.push(excep)
        rescue Tw::Error => e
          $stderr.puts("#{e.message} (In-reply-to-tatus-id: #{tw.in_reply_to_status_id})")
          $stderr.puts()
          excep = e
          is_quit = true
        rescue => e
          $stderr.puts("Warning: In-reply-to-status-id: #{tw.in_reply_to_status_id}.")
          $stderr.puts("Warning: #{e.message}")
          $stderr.puts()
          $stderr.puts(e.backtrace)
          excep = e
          is_quit = true
        ensure
          counter += 1
        end
      end
      return tweet
    end

  end

end
