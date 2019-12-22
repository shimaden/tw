# encoding: UTF-8
#
# The Rainbow library is used to colorization.
# See: sickill/rainbow https://github.com/sickill/rainbow
#
require 'stringio'
require 'time'
require File.expand_path('tweet_text_colorizer', File.dirname(__FILE__))

module Tw::App
  class Renderer

    FMT_NONE    = 0
    FMT_TEXT    = 1
    FMT_COLOR   = 2
    FMT_JSON    = 3
    FMT_ID      = 4
    FMT_CSV     = 5
    FMT_SIMPLE  = 6
    FMT_FULL    = 7
    FMT_ARRAY   = 101  # for reply formatter and memtion formatter

    class RenderingFormatError < ::ArgumentError; end

    def initialize()
      @silent_mode = false
    end

    def silent_mode=(bool)
      @silent_mode = bool ? true : false
    end

    def silent_mode()
      @silent_mode
    end

    def puts(s)
      if s.is_a?(Array) then
        s.each do |line|
          $stdout.puts(line)
        end
      else
        $stdout.puts(s) unless self.silent_mode()
      end
    end

    def print(s)
      unless self.silent_mode() then
        $stdout.print(s)
        $stdout.flush()
      end
    end

    def remove_retweets?()
      return !!@no_retweets
    end

    #----------------------------------------------------------------
    # Display tweets, direct messages or user information
    #----------------------------------------------------------------
    def display(container, format, separator: nil, current_user_id: nil, no_retweets: false, options: {})

      if !container.is_a?(Array) then
        raise TypeError.new(blderr(__FILE__, __LINE__,
                "Container must be an array " \
                "but #{container.class} is given."))
      end
      if !format.is_a?(Hash) then
        raise TypeError.new(blderr(__FILE__, __LINE__,
                "format must be a Hash but #{format.class} is given."))
      end

      if container.size == 0 then
        return
      end

      if ![FMT_TEXT, FMT_COLOR, FMT_JSON, FMT_ID, FMT_SIMPLE, FMT_FULL].freeze.include?(format[:data_fmt]) then
        raise RenderingFormatError.new("Invalid rendering format: #{format[:data_fmt].inspect}.")
      end

      if !separator.is_a?(String) then
        raise TypeError(blderr(__FILE__, __LINE__,
                  "separator must be a string."))
      end

      @separator       = separator
      @current_user_id = current_user_id
      @no_retweets     = no_retweets

      if container[0].is_a?(Tw::Tweet) then
        self.display_tweets(container, format)
      elsif container[0].is_a?(Tw::DMTweet) then
        self.display_direct_messages(container, format)
      elsif container[0].is_a?(Tw::User) then
        if format[:data_fmt] == FMT_SIMPLE then
          self.display_users_in_simple_format(container, format, options[:last_update_time])
        elsif format[:data_fmt] == FMT_FULL then
          self.display_users(container, format, options[:last_update_time])
        else
          self.display_users(container, format, options[:last_update_time])
        end
      else
        raise TypeError.new(blderr(__FILE__, __LINE__,
                "container must be an array of one of Tw::Tweet, " \
                "Tw::DMTweet or Tw::User but #{container.class} is given."))
      end
    end

    #----------------------------------------------------------------
    # Display the stream message
    #----------------------------------------------------------------
    #def display_stream_message(obj, format, separator: separator)
    def display_stream_message(obj, format, separator: nil)
      if ![FMT_TEXT, FMT_COLOR, FMT_JSON].include?(format[:data_fmt]) then
        raise RenderingFormatError.new("Invalid rendering format (maybe only in this context though).")
      end
      case format[:data_fmt]
      when FMT_COLOR
        header = "STREAM MESSAGE>>>"
        contents = "#{header} #{obj.to_s}\n#{separator}"
      when FMT_TEXT
        header = "STREAM MESSAGE>>>"
        if format == 'color' then
          header = Rainbow(header).color(80,200,80)
        end
        contents = "#{header} #{obj.to_s}\n#{separator}"
      when FMT_JSON
        contents = obj.to_json
      end
      puts(contents)
    end

        #----------------------------------------------------------------
    protected
        #----------------------------------------------------------------

    #----------------------------------------------------------------
    # $stdout がコンソールに接続されていれば true。
    #----------------------------------------------------------------
    def stdout_to_console?
      return !($stdout.stat.file? || $stdout.stat.pipe?)
    end

    #----------------------------------------------------------------
    # フォロー関係を示すマークを返す。
    #----------------------------------------------------------------
    def get_follow_relation_sign(tweet, options)
      color_mode = options[:color_mode]
      force_regular_tweet = options[:force_regular_tweet]

      if tweet.kind.regular_tweet? || force_regular_tweet then
        twt = tweet
      elsif tweet.kind.retweet? then
        twt = tweet.retweeted_status
      elsif tweet.kind.result_of_retweet? then
        twt = tweet
      end

      following    = twt.user.following
      followed_by  = twt.user.followed_by
      sent_user_id = twt.user.id

      if following && followed_by then
        sign   = "(^_^)"     # 相互フォロー
      elsif following && !followed_by then
        sign   = "(`･ω･´)" # 片思いフォロー
      elsif !following && followed_by then
        sign   = "|дﾟ)ﾉ"    # 方思われフォロー
      else
        if @current_user_id == sent_user_id then
          sign = "σ(・・*)" # 自分自身
        else
          sign = "(- -)"     # 無関係
        end
      end
      if color_mode then
        sign = Rainbow(sign).fg(:magenta).bright
      end
      return sign
    end

    #----------------------------------------------------------------
    # 鍵垢マークを返す。
    #----------------------------------------------------------------
    def get_protected_sign(tweet, options)
      color_mode = options[:color_mode]

      if tweet.retweeted_status? then
        sign = tweet.retweeted_status.user.protected ? "LCKD" : ""
      else
        sign = tweet.user.protected ? "LCKD" : ""
      end
      if color_mode && sign.size > 0 then
        sign = Rainbow(sign).fg(:cyan)
      end
      return sign
    end

    #----------------------------------------------------------------
    # ヘッダを作成する。
    #----------------------------------------------------------------
    def create_header(tweet, options)
      color_mode = options[:color_mode]

      if tweet.kind.regular_tweet? then
        twt = tweet
      elsif tweet.kind.retweet? then
        twt = tweet.retweeted_status
      elsif tweet.kind.result_of_retweet? then
        twt = tweet
      end

      if color_mode then
        screen_name     = twt.user.screen_name.color(48, 180, 48) \
                             .bright.underline
        followers_count = twt.user.followers_count
        user_name       = twt.user.name.color(170, 170, 250).bright
      else
        screen_name     = twt.user.screen_name
        followers_count = twt.user.followers_count
        user_name       = twt.user.name
      end

      result = sprintf("[[@%s (%d)|%s",
                        screen_name,              # @usakonigohan
                        twt.user.followers_count, # Number of followers
                        user_name                 # うさこにごはん
                        )
      options[:force_regular_tweet] = true
      follow_relation_sign = self.get_follow_relation_sign(twt, options)

      if follow_relation_sign.length > 0 then
        result += "|#{follow_relation_sign}"
      end
      protected_sign = self.get_protected_sign(twt, options)
      if protected_sign.length > 0 then
        result += "|#{protected_sign}"
      end
      if !twt.unreadable_tweet? then
        result += twt.created_at.localtime.strftime('|%Y-%m-%d %H:%M:%S')
      end
      result += "]]\n"

      return result
    end

    #----------------------------------------------------------------
    # 隠しプリフィックス hidden prefix を表示する。
    #----------------------------------------------------------------
    def create_hidden_prefix(tweet, options)
      return "" if !(options[:display_text_range] && tweet.hidden_mentions?)
      if self.stdout_to_console? && options[:color_mode] then
        esc_begin = TweetTextColorizer::BLUE
        esc_end   = TweetTextColorizer::CLEAR
      else
        esc_begin = esc_end = ""
      end

      screen_names = ""
      tweet.hidden_mentions.each.with_index do |um, idx|
        if idx == 0 then
          screen_names = "#{esc_begin}@#{um.screen_name}#{esc_end}"
        else
          screen_names += " #{esc_begin}@#{um.screen_name}#{esc_end}"
        end
      end
      return screen_names.size > 0 ? "(prefix) #{screen_names}\n" : ""
    end

    #----------------------------------------------------------------
    # 隠しサフィックス hidden suffix を表示する。
    #----------------------------------------------------------------
    def create_hidden_suffix(tweet, options)
      return "" if !options[:display_text_range]
      tw = tweet.retweeted_status? ? tweet.retweeted_status : tweet

      if self.stdout_to_console? && options[:color_mode] then
        esc_begin = TweetTextColorizer::DARK_WHITE
        esc_end   = TweetTextColorizer::CLEAR
      else
        esc_begin = esc_end = ""
      end

      suffix_arr = []
      if tw.extended_entities? then
        if tw.extended_entities.media? then
          tw.extended_entities.media.each.with_index do |ee, idx|
            id  = ee.id
            case ee.type
            when 'photo' then
              url = "#{ee.media_url_https}:large"
              sfx_name = "Photo"
            when 'video' then
              #url = ee.mp4? ? ee.best_mp4_url : "#{entities.media[0].media_url_https}:large"
              url = ee.mp4? ? ee.best_mp4_url : "#{entities.media[0].media_url_https}"
              sfx_name = "Video"
            when 'animated_gif' then
              url = ee.video_info.variants[0].url
              sfx_name = "Anime"
            else
              url = ee.media_url_https
              sfx_name = "Media"
            end
            if sfx_name == "Media" then
              suffix_arr.push(["(#{sfx_name})", "#{ee.type.capitalize}: #{id}: #{url}"])
            else
              suffix_arr.push(["(#{sfx_name})", "#{id}: #{url}"])
            end
          end
        end
      end

      if tw.quoted_status? then
        qtw = tw.quoted_status
        if qtw.new_140_count_feature? then
          range = qtw.display_text_range
          text = qtw.full_text[range[0]..range[1]]
        else
          text = qtw.text
        end
        suffix_arr.push(["(QT)", "@#{qtw.user.screen_name}: #{text.escape_line_feed().decode_html()}"])
        suffix_arr.push(["(Url)", "#{qtw.url}"])
      end

      suffix = ""
      if suffix_arr.size > 0 then
        suffix_arr.each do |sfx|
          suffix += "#{sfx[0]} #{esc_begin}#{sfx[1]}#{esc_end}\n" if sfx.size > 0
        end
      end
      return suffix
    end

    #----------------------------------------------------------------
    # Retweeted by を作成する。
    #----------------------------------------------------------------
    def create_retweeted_by(tweet, options)
      return "" if !tweet.retweeted_status?

      color_mode = options[:color_mode]
      rt = "RT"

      if tweet.result_of_retweet? then
        twt = tweet.retweeted_status
        screen_name = "@#{tweet.retweeted_status.user.screen_name}"
        user_name   = tweet.retweeted_status.user.name
        followers_count = tweet.retweeted_status.user.followers_count
      else
        twt = tweet
        screen_name  = tweet.user.screen_name
        user_name    = tweet.user.name
        followers_count = tweet.user.followers_count
      end

      if color_mode then
        rt           = Rainbow(rt).fg(:yellow)
        screen_name  = screen_name.color(48, 180, 48)
        user_name    = user_name.color(170, 170, 250)
      end

      result = sprintf("[%s] [@%s (%d)|%s",
                        rt,
                        screen_name,      # @usakonigohan
                        followers_count,  # Number of followers
                        user_name         # うさこにごはん
                      )
      follow_relation_sign = self.get_follow_relation_sign(twt, options)
      if follow_relation_sign.length > 0 then
        result += "|#{follow_relation_sign}"
      end
      protected_sign = self.get_protected_sign(twt, options)
      if protected_sign.length > 0 then
        result += "|#{protected_sign}"
      end
      if !twt.unreadable_tweet? then
        result += twt.created_at.localtime.strftime('|%Y-%m-%d %H:%M:%S')
      end
      result += "]\n"

      return result
    end

    #----------------------------------------------------------------
    # via xxx. 19 RTs, 30 Favs の行を作る。
    #----------------------------------------------------------------
    def create_via_rt_fav(tweet, options)
      color_mode = options[:color_mode]

      if tweet.retweeted_status? then
        tw = tweet.retweeted_status
      else
        tw = tweet
      end

      via       = "via"
      client    = "#{tw.client}"
      rt        = "#{tw.retweet_count}"
      fav       = "#{tw.favorite_count}"
      rt_sign   = "RT"
      fav_sign  = "Fav"
      retweeted = tw.retweeted ? "yes" : "no"
      favorited = tw.favorited ? "yes" : "no"

      if tw.place.not_nil? then
        from       = "From"
        place_name = tw.place.full_name
        place_type = tw.place.place_type
        place      = "#{place_name} (#{place_type})"
      end

      if color_mode then
        rt_sign  = rt_sign .color(  0,170, 0)  # green
        fav_sign = fav_sign.color(180,120, 0)  # orange
        if tw.place.not_nil? then
          place = place.color(110,220,64).underline
        end
      end

      result  = "#{rt} RTs #{fav} Favs (#{via} #{client}) " \
              + "#{rt_sign} #{retweeted} #{fav_sign} #{favorited}"
      if tw.place.not_nil? then
        result += " #{from} #{place}"
      end

      return "#{result}\n"
    end

    #----------------------------------------------------------------
    # in reply to の文字列を作る。
    #----------------------------------------------------------------
    def create_in_reply_to_str(tweet, options)
      color_mode = options[:color_mode]

      if tweet.in_reply_to_status_id? then
        url = tweet.in_reply_to_url
        if color_mode then
          url = Rainbow(url).fg(:yellow)
        end
        in_reply_to = "in reply to : #{url}\n"
      else
        in_reply_to = ""
      end
      return in_reply_to
    end

    #----------------------------------------------------------------
    # text 中の URL t.co を expanded_url に置き換える。
    #----------------------------------------------------------------
    def replace_url_with_expanded_url(text, tweet)
      return text if !tweet.entities? || tweet.entities.urls.to_a.size == 0
      urls = {}
      tweet.entities.urls.to_a.each{|e| urls[e.url] = e.expanded_url}
      urls.each do |url, exp_url|
        text.gsub!(url, exp_url)
      end
      return text
    end

    #----------------------------------------------------------------
    # 本文を作成する。
    #----------------------------------------------------------------
    def create_text(tweet, options)
      color_mode = options[:color_mode]
      tw = tweet.retweeted_status? ? tweet.retweeted_status : tweet
      if self.stdout_to_console? && color_mode then
        # stdout がコンソールにつながっていて、かつ color_mode = true
        # なら text に色をつける。
        colorizer = Tw::App::TweetTextColorizer.new(tweet)
        text = colorizer.perform(color_mode)
      else
        # text に色をつける必要なし。
        if tw.hidden_prefix? || tw.hidden_suffix? then
          # text から display_range の部分だけ切り出す。
          range = tw.display_text_range
          text = tw.full_text[range[0], range[1] - range[0]]
        else
          # 単に text または full_text をコピーする。
          text = tw.new_140_count_feature? ? tw.full_text : tw.text
        end
      end

      # text 中に t.co の URL があれば extended_url に置き換える。
      text = self.replace_url_with_expanded_url(text, tw)

      return "#{text}\n"
    end

    #----------------------------------------------------------------
    # URL を作成する。
    #----------------------------------------------------------------
    def create_url(tweet, options)
      color_mode = options[:color_mode]

      if tweet.retweeted_status? then
        orig_url      = tweet.retweeted_status.url
        retweeter_url = tweet.url

        if color_mode then
          retweeter_url = Rainbow(retweeter_url).fg(:yellow)
        end

        if tweet.result_of_retweet? then
          url  = "URL (RTed)  : #{retweeter_url}\n"
        else
          url  = "URL (RTer\'s): #{retweeter_url}\n"
        end
        url += "URL (orig)  : #{orig_url}\n"
      else
        url  = "URL: #{tweet.url}\n"
      end

      tweet_url = tweet.url
      if color_mode then
        tweet_url = tweet_url.color(120,120,200)
      end

      url = "URL: #{tweet_url}\n"
      if tweet.retweeted_status? then
        url += " Orig: #{tweet.retweeted_status.url}\n"
      end

      return url
    end

    #----------------------------------------------------------------
    # 鍵垢でアクセスできないツイート用のフォーマット。
    #----------------------------------------------------------------
    def format_for_unreadable_tweet(tweet, options)
      result  = self.create_header(tweet, options)
      result += "<Protected>\nURL: #{tweet.url}\n"
      return result
    end

    #----------------------------------------------------------------
    # 通常のツイート用のフォーマット
    #----------------------------------------------------------------
    def get_string_for_regular_tweet(tweet, options)
      result  = self.create_header(tweet, options)
      result += self.create_retweeted_by(tweet, options)
      result += self.create_hidden_prefix(tweet, options)
      result += self.create_text(tweet, options).decode_html()
      result += self.create_hidden_suffix(tweet, options)
      result += self.create_via_rt_fav(tweet, options)
      result += self.create_in_reply_to_str(tweet, options)
      result += self.create_url(tweet, options)
      return result
    end

    #----------------------------------------------------------------
    # ただ 1 つのツイートを、デフォルトの形式でフォーマットした文字列
    # を返す。
    # もし tweet.user.tweet_accessible? が false であれば（フォローして
    # いない鍵付きのユーザ）、返される文字列は tweet.user に含まれる
    # ユーザ情報のみになる。
    #
    # 引数:
    #   tweet: Tw::Tweet 型のクラス
    #----------------------------------------------------------------
    def format_in_default(tweet, options)
      if tweet.unreadable_tweet? then
        result = self.format_for_unreadable_tweet(tweet, options)
      else
        result = self.get_string_for_regular_tweet(tweet, options)
      end
      return "#{result}#{@separator}"
    end

    #----------------------------------------------------------------
    # in_reply_to_status のチェーンをたどって
    # ツイートをデフォルト表示用にフォーマットし、その文字列を返す。
    # フォーマットは、渡された tweet から in_iply_to で続く限り
    # 行われる。
    #----------------------------------------------------------------
    def format_default_with_reply_chain(tweet, options = {})
      tweet_array = []

      tw = tweet
      while !tw.nil? do
        tweet_array.push(tw)
        tw = tw.in_reply_to_status
      end
      contents = ""
      tweet_array.reverse_each do |tw|
        contents += self.format_in_default(tw, options)
      end

      return contents
    end

    #----------------------------------------------------------------
    # ツイートIDの文字列を作成する。
    #----------------------------------------------------------------
    def format_id(tweet, options)
      array = []
      tw = tweet
      while tw do
        array << tw.id.to_s
        tw = tw.in_reply_to_status
      end
      return array.join(',')
    end

    #----------------------------------------------------------------
    # Display tweets to the standard output.
    #----------------------------------------------------------------
    def display_tweets(tweetArr, format)
      begin
        tweetArr = [tweetArr] unless tweetArr.kind_of?(Array)

        disp_tweets = tweetArr.flatten.sort_by{|tw| tw.id}.uniq{|tw| tw.id}

#$stderr.puts("disp_tweets.size       : #{disp_tweets.size}")
        if self.remove_retweets? then
          # リツイートでない普通のツイートの配列
          regular_tweets = disp_tweets.select{|tw| tw.kind.regular_tweet?}
#$stderr.puts("regular_tweets.size    : #{regular_tweets.size}")
          # リツイートの配列
          retweets = disp_tweets.select{|tw| tw.retweeted_status?}
#$stderr.puts("retweets.size          : #{retweets.size}")

          # リツイートされたオリジナルのツイートの配列
          retweeted_original = retweets.inject(Array.new()){|rt_orig, rt|
            if !rt_orig.find{|tw| rt.retweeted_status.id == tw.id} then
              rt_orig << rt.retweeted_status
            end
            rt_orig
          }.sort_by{|rt| rt.id}
#$stderr.puts("retweeted_original.size: #{retweeted_original.size}")

          # 普通のツイートに、リツイートされたオリジナルのツイートを、
          # 重複しないように加える。
          disp_tweets = (regular_tweets + retweeted_original).inject(Array.new()){|disp_tw, tw|
            if !disp_tw.find{|d_tw| d_tw.id == tw.id} then
              disp_tw << tw
            end
            disp_tw
          }.sort_by{|tw|
            tw.id
          }.uniq{|tw|
            tw.id
          }
#$stderr.puts("disp_tweets.size       : #{disp_tweets.size}")

        end

        disp_tweets.each do |tweet|
          case format[:data_fmt]
          when FMT_TEXT
            user = nil
            options = {:color_mode => false, :display_text_range => true}
            contents = self.format_default_with_reply_chain(tweet, options)
          when FMT_COLOR
            options = {:color_mode => true, :display_text_range => true}
            contents = self.format_default_with_reply_chain(tweet, options)
          when FMT_JSON
            contents = tweet.to_json
          when FMT_ID
            contents = self.format_id(tweet, options)
          end
          puts(contents)
        end
      #rescue Errno::EPIPE
      rescue SystemCallError
        raise
      rescue ::TypeError
        raise
      rescue => e
        $stderr.puts(experr(__FILE__, __LINE__, e))
        $stderr.puts(Tw::BACKTRACE_MSG)
        raise if ENV["TWBT"]
      end
    end

    #----------------------------------------------------------------
    # Build a header for a direct message
    #----------------------------------------------------------------
    def create_header_for_dm(dm, options)
      color_mode = options[:color_mode]

      if dm.received? then
        user      = dm.sender
        direction = "From: "
        lock_sign = user.protected ? "LCKD" : ""
      elsif dm.sent? then
        user      = dm.recipient
        direction = "To: "
        lock_sign = user.protected ? "LCKD" : ""
      else
        raise TypeError.new(blderr(__FILE__, __LINE__,
                "dm must be one of Tw::DMReceive and Tw::DMSent"))
      end
      if lock_sign.size > 0 then
        if color_mode then
          lock_sign = "|#{Rainbow(lock_sign).fg(:cyan)}"
        end
        lock_sign = "|#{lock_sign}"
      end

      if user.following && user.followed_by then
        sign   = "(^_^)"     # 相互フォロー
      elsif user.following && !user.followed_by then
        sign   = "(`･ω･´)" # 片思いフォロー
      elsif !user.following && user.followed_by then
        sign   = "|дﾟ)ﾉ"    # 方思われフォロー
      else
        if @current_user_id == user.id then
          sign = "σ(・・*)" # 自分自身
        else
          sign = "(- -)"     # 無関係
        end
      end
      screen_name = user.screen_name
      if color_mode then
        screen_name = user.screen_name.color(48, 180, 48) \
                           .bright.underline
        sign      = Rainbow(sign).fg(:magenta).bright
        direction = direction.color(170, 170, 215).bright
      end

      header = sprintf("[[%s@%s(%d)|%s|%s%s%s]]\n",
                          direction,
                          screen_name,
                          user.followers_count,
                          user.name,
                          sign,
                          lock_sign,
                          dm.created_at.localtime.strftime('|%Y-%m-%d %H:%M:%S')
                      )

      return header
    end

    #----------------------------------------------------------------
    # Build media URLs
    #----------------------------------------------------------------
    def create_media_urls_for_dm(dm, options = {})
      result = ""
      if dm.entities.media? then
        dm.entities.media.each do |med|
          result = "Media: #{med.media_url_https}:large\n"
        end
      end
      return result
    end

    #----------------------------------------------------------------
    # Return text of DM in plain text
    #----------------------------------------------------------------
    def format_dm_default(dm, options = {})
      result  = self.create_header_for_dm(dm, options)
      result += dm.text.decode_html() + "\n"
      result += self.create_media_urls_for_dm(dm, options)
      #result += dm.url() + "\n"
      return "#{result}\n"
    end

    #----------------------------------------------------------------
    # Display direct messages
    #----------------------------------------------------------------
    def display_direct_messages(dmArr, format)
      begin
        dmArr.inject({}){|tweetHash, dm|
          # tweetHash は Tw::DMTweet を格納するための Hash。injedt()で{}に
          # 初期化されている。
          # キーは、格納する Tw::DMTweet オブジェクト自体の Tw::DMTweet.id。
          tweetHash[dm.id] = dm
          # そして、そのハッシュを返す。
          tweetHash
        }.values.sort{|dm1, dm2| # values メソッドはハッシュを配列に変換。
                                   # Tw::Tweet オブジェクトの入った配列を sort()。
          dm1.id <=> dm2.id  # ソート条件。
        }.each{|dm|    # 配列から Tw::Tweet 型のインスタンスを取り出す。
          case format[:data_fmt]
          when FMT_TEXT
            user = nil
            options = { }
            contents = self.format_dm_default(dm, options)
          when FMT_COLOR
            options = {:color_mode => true}
            contents = self.format_dm_default(dm, options)
          when FMT_JSON
            contents = dm.to_json
          end
          puts(contents.safe_str)
        }
      rescue => e
        $stderr.puts experr(__FILE__, __LINE__, e)
        $stderr.puts Tw::BACKTRACE_MSG
        raise if ENV["TWBT"]
      end
    end

    #----------------------------------------------------------------
    # Yes or No
    #----------------------------------------------------------------
    def yes_or_no(value)
      return value ? "Yes" : "No"
    end

    #----------------------------------------------------------------
    # Display tweets to the standard output.
    #----------------------------------------------------------------
    def display_users(userArray, format, last_update_time)
      userArray.each do |user|
        case format[:data_fmt]
        when FMT_TEXT, FMT_COLOR, FMT_FULL
          options = (format == 'color') ? {:color_mode => true} : {}
          url = ""
          if user.status? then
            url = "https://twitter.com/#{user.screen_name}/status/#{user.status.id}"
          end
          s = StringIO.new
          s.puts("Last update   : #{last_update_time}")
          s.puts("Screen name   : @#{user.screen_name}")
          s.puts("Name          : #{user.name}")
          s.puts("ID            : #{user.id}")
          s.puts("Created at    : #{user.created_at.localtime}")
          s.puts("Tweets        : #{user.statuses_count}")
          s.puts("Follow        : #{user.friends_count}")
          s.puts("Follower      : #{user.followers_count}")
          s.puts("Favorites     : #{user.favorites_count}")
          s.puts("Following     : #{self.yes_or_no(user.following)}")
          s.puts("Followed by   : #{self.yes_or_no(user.followed_by)}")
          s.puts("Listed        : #{user.listed_count}")
          s.puts("Protected     : #{self.yes_or_no(user.protected)}")
          s.puts("Follow request: #{user.follow_request_sent ? "Sent" : "No"}")
          s.puts("Verified      : #{self.yes_or_no(user.verified)}")
          s.puts("Translator    : #{self.yes_or_no(user.is_translator)}")
          s.puts("Language      : #{user.lang}")
          s.puts("Location      : #{user.location}")
          s.puts("Time zone     : #{user.time_zone}")
          s.puts("UTC offset    : #{user.utc_offset}")
          s.puts("User page     : #{(user.url?) ? user.url : "None"}")
          #s.puts("Home timeline : http://twitter.com/account/redirect_by_id?id=#{user.id}")
          s.puts("Home timeline : https://twitter.com/intent/follow?user_id=#{user.id}")
          s.puts("Description   : #{user.description}")
          if user.entities.url? then
            user.entities.url.urls.each do |url|
              s.puts("URL           : #{url.expanded_url}")
            end
          end
          if user.status? then
            s.puts("Latest tweet  : #{url}")
            if user.status.new_140_count_feature? then
              s.puts("#{user.status.full_text.decode_html()}")
            else
              s.puts("#{user.status.text.decode_html()}")
            end
          else
            s.puts("Latest tweet  : None")
          end
          s.rewind()
          puts("#{s.read}#{@separator}")
        when FMT_JSON
          puts(user.to_json)
        end
      end
    end

    #----------------------------------------------------------------
    # Display tweets to the standard output.
    #----------------------------------------------------------------
    def display_users_in_simple_format(userArray, format, last_update_time)
      if format[:data_fmt] != FMT_SIMPLE then
        raise RenderingFormatError.new("Invalid rendering format (maybe only in this context though).")
      end
      userArray.each do |user|
        options = (format == 'color') ? {:color_mode => true} : {}
        url = ""
        if user.status? then
          url = "https://twitter.com/#{user.screen_name}/status/#{user.status.id}"
        end
        if user.id == @current_user_id then
          relationship = "  "
        else
          relationship = (user.following ? 'F' : 'x') + (user.followed_by ? 'F' : 'x')
        end
        msg = sprintf("%19d @%-15s %-7s %s: %s\n",
                    user.id,
                    user.screen_name,
                    sprintf("(%4d)", user.followers_count),
                    relationship,
                    user.name
                    #user.description.gsub(/\r/, '\r').gsub(/\n/, '\n')
        )
        puts(msg)
      end
    end

    #----------------------------------------------------------------
    # 鍵垢で、見られない時に出すメッセージ
    #----------------------------------------------------------------
    def protected_info(user)
      #
      # gem install locale
      if LocaleInspector.can_use_Japanese? then
        msg = "@#{user.screen_name}さんのツイートは非公開です。\n"  \
              "許可されたフォロワーのみが @#{user.screen_name} "    \
              "さんのツイートやアカウントを見ることが出来ます。"    \
              "[フォロー] ボタンをクリックしてフォローリクエストを" \
              "送りましょう。\n"
      else
        msg = "@#{user.screen_name}'s tweets are protected.\n"       \
              "Only confirmed followers have access to "             \
              "@#{user.screen_name}'s Tweets and complete profile. " \
              "Click the \"Follow\" button to send a follow "        \
              "request.\n"
      end
      return msg
    end

  end

end
