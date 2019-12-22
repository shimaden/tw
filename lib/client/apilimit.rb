# encoding: UTF-8
# このファイルはＵＴＦ－８です。

module Tw
  class APILimit
    attr_reader :rate_limit_context, :access_token, :resources

    class NoAPINameError < ::NameError; end

    class RateLimitContext
      attr_reader :access_token
      def initialize(hash)
        @access_token = hash[:access_token]
      end
      def to_s()
        return "access_token:#{@access_token}"
      end
    end

    class Limits
      attr_reader :limit, :remaining, :reset, :reset_at, :reset_in
      def initialize(limits)
        @limit     = limits[:limit]
        @remaining = limits[:remaining]
        @reset     = limits[:reset]
        @reset_at  = Time.at(@reset)
        @reset_in  = [(@reset_at - Time.now).ceil, 0].max
      end
      def to_s()
        return "limit:#{@limit},remaining:#{@remaining},reset:#{@reset}"
      end
    end

    class API
      attr_reader :name, :limits
      def initialize(name, limits)
        @name      = name.to_s
        @limits    = Limits.new(limits)
      end
      def to_s()
        return "#{@name},#{@limits.to_s}"
      end
    end

    class Category
      attr_reader :name, :endpoints
      def initialize(name, value)
        @name      = name.to_s
        @endpoints = value.collect {|key, val| API.new(key, val)}
      end
      def each()
        ret = nil
        if block_given? then
          @endpoints.each do |category|
            yield(category)
          end
          ret = self
        else
          ret = @endpoints.each()
        end
        return ret
      end
      def endpoint(name)
        return @endpoints.find {|ep| ep.name == name}
      end
      def to_s()
        return @endpoints.collect {|ep| "#{@name},#{ep.to_s}"}.join("\n") + "\n"
      end
    end

    class Resources
      attr_reader :categories
      def initialize(hash)
        @categories = hash.collect do |category, endpoint|
          Category.new(category, endpoint)
        end
      end
      def category(name)
        category = @categories.find {|cat| cat.name == name}
        if category.nil? then
          raise NoAPINameError.new("No such API category: #{name}.")
        end
        return category
      end
      def each()
        ret = nil
        if block_given? then
          @categories.each do |category|
            yield(category)
          end
          ret = self
        else
          ret = @categories.each()
        end
        return ret
      end
      def to_a()
        return @categories
      end
      def to_s()
        s = @categories.join("")
        return s
      end
    end

    class APILimitData
      attr_reader :rate_limit_context, :resources
      def initialize(body)
        @rate_limit_context = RateLimitContext.new(body[:rate_limit_context])
        @resources          = Resources.new(body[:resources])
      end
      def to_s()
        return "rate_limit_context:\n#{@rate_limit_context}\n" \
               "resources:\n#{@resources}"
      end
    end

    #
    # REST API v1.1 Resources
    #

    CONSTVAL = Set.new(["aa", "bb", "cc"])

    # Timelines
    HOME_TIMELINE           = "statuses/home_timeline"
    USER_TIMELINE           = "statuses/user_timeline"

    MEMTIONS_TIMELINE       = "statuses/mentions_timeline"
    RETWEETS_OF_ME          = "statuses/retweets_of_me"

    # Tweets

    # Search

    # Stream

    # Direct Messages
    DIRECT_MESSAGES         = "direct_messages"
    DIRECT_MESSAGES_SENT    = "direct_messages/sent"
    DIRECT_MESSAGES_SHOW    = "direct_messages/show"
    DIRECT_MESSAGES_DESTROY = "direct_messages/destroy"
    DIRECT_MESSAGES_NEW     = "direct_messages/new"

    # Friends & Followers
    FOLLOWERS_LIST          = "followers/list"
    FOLLOWERS_IDS           = "followers/ids"

    # Users
    BLOCK_LIST              = "blocks/list"
    BLOCK_IDs               = "blocks/ids"
    USER_LOOKUP             = "users/lookup"
    USERS_SHOW              = "users/show"
    USERS_SEARCH            = "users/search"
    USERS_CONTRIBUTEES      = "users/contributees"
    USERS_CONTRIBUTORS      = "users/contributors"

    # Suggested Users

    # Favorites
    FAVORITES_LIST          = "favorites/list"
    FAVORITES_DESTROY       = "avorites/destroy"
    FAVORITES_CREATE        = "favorites/create"

    # Lists

    # Saved Searches

    # Trends

    # Places & Geo
    GEO_ID_PLACEID           = "geo/id/:place_id"
    GEO_REVERSE_GEOCODE      = "geo/reverse_geocode"
    GEO_SEARCH               = "geo/search"
    GEO_SIMILAR_PLACE        = "geo/similar_places"
    GEO_PLACE                = "geo/place"

    # Help

    # Spam Reporting
    USERS_REPORT_SPAM        = "users/report_spam"

    # URL for API rate limit
    END_POINT = '/1.1/application/rate_limit_status.json'


    #------------------------------------------------
    # イニシャライザ
    # 戻り値:
    #   TwitterRequester 型
    #------------------------------------------------
    def initialize(requester)
      @requester = requester
    end

    #------------------------------------------------
    # 文字列 apiname で示される API の呼出残量を取得
    # して返す
    # 例: #rate_limit("/followers/list")
    #------------------------------------------------
    def rate_limit(apiname = nil)
      if apiname.nil? then
        ret = self.get_api_limit()
      else
        api_rate_limit = self.get_an_api_rate_limit(apiname)
        if api_rate_limit.nil? then
          raise NoAPINameError.new("No such API: #{apiname}")
        end
        ret = api_rate_limit
      end
      return ret
    end

    # followers/ids
    def followers_ids
      return rate_limit(FOLLOWERS_IDS)
    end

    # followers/list
    def followers_list
      return rate_limit(FOLLOWERS_LIST)
    end

    # statuses/home_timeline
    def home_timeline
      return rate_limit(HOME_TIMELINE)
    end

      #------------------------------------------------
    protected
      #------------------------------------------------

    #------------------------------------------------
    # API の rate limit を Twitter から HTTPS で取得する。
    #------------------------------------------------
    def get_api_limit()
      # Twitter API の END_POINT に GET メソッド
      options = {}
      json = @requester.get(END_POINT, options)
      api_limit_data = APILimitData.new(json)
      return api_limit_data
    end

    def get_an_api_rate_limit(apiname)
      api_limit_data = self.get_api_limit()
      category = apiname.split(/\//)[0]
      result = api_limit_data.resources.category(category)
               .endpoint("/" + apiname)
      return result
    end

  end
end

# Twitter API の戻り値ヘッダの例
# HTTP/1.1 200 OK
# X-Access-Level: read-write
# Content-Type: application/json;charset=utf-8
# Last-Modified: Mon, 24 Sep 2012 21:02:03 GMT
# Expires: Tue, 31 Mar 1981 05:00:00 GMT
# Pragma: no-cache
# Cache-Control: no-cache, no-store, must-revalidate, pre-check=0, post-check=0
# Set-Cookie: guest_id="xxxxxxxx"; Expires=Wed, 24-Sep-2014 21:02:03
# GMT; Path=/; Domain=.twitter.com
# Set-Cookie: lang=ja
# Status: 200 OK
# X-Transaction: xxxxxxxx
# X-Frame-Options: SAMEORIGIN
# Date: Mon, 24 Sep 2012 21:02:03 GMT
# Content-Length: 13390
# X-Rate-Limit-Limit: 15
# X-Rate-Limit-Remaining: 14
# X-Rate-Limit-Reset: 1348521423
# Server: tfe

# REST API Rate Limiting in v1.1
# https://dev.twitter.com/docs/rate-limiting/1.1
#
# 1. Per User or Per Application
#
# If a method allows for 15 requests per rate limit window, then it allows 
# you to make 15 requests per window per leveraged access token.
#
# メソッドが割合制限ウィンドウあたり 15 のリクエストを認めている場合、利用
# 可能なアクセス・トークンあたりにつき 1 ウィンドウあたり 15 のリクエストを
# 送ることができます。
#
# 2. 15 Minute Windows
#
# Rate limits in version 1.1 of the API are divided into 15 minute 
# intervals, which is a change from the 60 minute blocks in version 1.0. 
# Additionally, all 1.1 endpoints require authentication, so no longer 
# will there be a concept of unauthenticated calls and rate limits. 
#
# API のバージョン 1.1 における割合制限は 15 分間隔に分割されていて、
# バージョン 1.0 の 20 分間隔から変更されている。
# さらに、1.1 のすべてのエンドポイントは認証を要求するため、非認証の呼出しや
# 割合制限の概念はなくなった。
#
# 2.1 Search
#
# Search will be rate limited at 180 queries per 15 minute window for the time 
# being, but we may adjust that over time. A friendly reminder that search 
# queries will need to be authenticated in version 1.1.
#
# 検索は、当面の間、15 分ウィンドウにつき 180 リクエストに割合制限されて
# います。しかしその値はそのうち調整するかもしれません。念のために申し上げて
# おくと、検索クエリはバージョン 1.1 では認証されていることが必要です。
#
# 3. HTTP Headers and Response Codes
#
# New HTTP headers are returned in v1.1. Ensure that you inspect these 
# headers, as they provide pertinent data on where your application is at 
# for a given rate limit on the method that you just utilized. Please note 
# that these headers are similar, but not identical to the headers returned 
# in API v1.0's rate limiting model.
#
# 新しくなった HTTP ヘッダは 1.1 形式で返されます。これらのヘッダは必ず
# 調べるようにしてください。それらのヘッダには、いま利用したばかりの
# メソッドの割合制限に関するデータが含まれており、その値はアプリケーションの
# 実行状況に依存するからです。これらのヘッダは同様であるが、API v1.0 の
# 割合制限モデルとまったく同じというわけではないことに留意してください。
#
# Note that these HTTP headers are contextual. When using app-only auth, 
# they indicate the rate limit for the application context. When using 
# user-based auth, they indicate the rate limit for that user-application 
# context.
#
# - X-Rate-Limit-Limit    : the rate limit ceiling for that given request
# - X-Rate-Limit-Remaining: the number of requests left for the 15 minute 
#                           window
# - X-Rate-Limit-Reset    : the remaining window before the rate limit 
#                           resets in UTC epoch seconds
#
# これらの HTTP ヘッダは文脈的であることに留意してください。app-only 認証で
# 使用している場合は、ヘッダはアプリケーション・コンテキスト用の割合制限を
# 示します。user-based 認証で使用している場合は、ユーザ・アプリケーション・
# コンテキスト用の割合制限を返します。
#
# - X-Rate-Limit-Limit    : 規定リクエスト回数の上限
# - X-Rate-Limit-Remaining: 残り 15 分ウィンドウのリクエスト残り回数
# - X-Rate-Limit-Reset    : 割合制限がリセットされるまでの残りウィンドウ
#                           （UTC UNIX時間）
#
# When an application exceeds the rate limit for a given API endpoint, 
# the Twitter API will now return an HTTP 429 “Too Many Requests” response 
# code instead of the variety of codes you would find across the v1's Search 
# and REST APIs.
#
# アプリケーションが規定の API エンドポイントを超過した場合、Twitter API は
# 現在、HTTP 429 "Too Many Requests" 応答コードを返します。
#
# If you hit the rate limit on a given endpoint, this is the body of the 
# HTTP 429 message that you will see: 
#
# もし規定のエンドポイントへの割合制限に達した場合は、このような  HTTP 429 
# メッセージの body に出会うでしょう。
#
# {
#   "errors": [
#     {
#       "code": 88,
#       "message": "Rate limit exceeded"
#     }
#   ]
# }
#

#----------------------------------------------------

# API の利用回数制限に達した。 X-Rate-Limit-Reset ヘッダーで示された UTC 
# 時間まで待ちましょう。
# http://www.antun.net/tips/api/twitter.html

# 公式ドキュメントの「レートリミットの詳細（英語）
# https://dev.twitter.com/docs/rate-limiting/1.1

# エンドポイントごとの15分当たりのリミット（英語）
# https://dev.twitter.com/docs/rate-limiting/1.1/limits

# X-Rate-Limit-Limit: the rate limit ceiling for that given request
# X-Rate-Limit-Remaining: 15 分ウィンドウ以内にリクエストできる回数
# X-Rate-Limit-Reset: 呼び出しカウントがリセットされる時刻
