# encoding: UTF-8
# このファイルはＵＴＦ－８です。

require File.expand_path('../../../utility/web-access/twitter_scraper', File.dirname(__FILE__))
require File.expand_path('update_options', File.dirname(__FILE__))
require File.expand_path('message_to_post', File.dirname(__FILE__))
require File.expand_path('message_printer', File.dirname(__FILE__))
require File.expand_path('reply_checker', File.dirname(__FILE__))

module Tw::App

  IMAGE_MEDIA_CATEGORY = 'tweet_image'
  GIF_MEDIA_CATEGORY   = 'tweet_gif'   # Animated GIF
  VIDEO_MEDIA_TYPE     = 'video/mp4'
  VIDEO_MEDIA_CATEGORY = 'tweet_video' # 'tweet_image' and 'tweet_gif'

  protected

  #================================================================
  # TweetPoster
  #================================================================
  class TweetPoster
    attr_reader :update_options

    EXIT_BY_NO = Tw::App::Executor::EXIT_BY_NO

    #---------------------------------------------------------------
    # Initializer
    #---------------------------------------------------------------
    def initialize(app, message, in_reply_to_status_id, is_auto_populate_reply, options)
      if !(in_reply_to_status_id.is_a?(Integer) || in_reply_to_status_id.nil?) then
        raise ::TypeError.new("in_reply_to_status_id must be " \
                              "an Integer value but #{in_reply_to_status_id.class}.")
      end
      @app                        = app  # Executor class
      @client                     = @app.client
      @message                    = message
      @in_reply_to_status_id      = in_reply_to_status_id
      @is_auto_populate_reply     = is_auto_populate_reply
      @options                    = options
      @update_options             = UpdateOptions.new()

      @update_options.set_in_reply_to_status_id(@in_reply_to_status_id)
    end
      #---------------------------------------------------------------
    protected
      #---------------------------------------------------------------
    #---------------------------------------------------------------
    # n 個の '-' の線の文字列を返す。
    #---------------------------------------------------------------
    def line_str(n)
      return "-" * n
      #line = ""
      #n.times do line += "-" end
      #return line
    end
    #---------------------------------------------------------------
    # 新形式のリプライかどうか。
    #---------------------------------------------------------------
    def auto_populate_reply?()
      return @is_auto_populate_reply
    end
    #---------------------------------------------------------------
    # Get in_reply_to_status if @options.dont_get_tweet? == false
    #---------------------------------------------------------------
    def get_in_reply_to_status()
      if !!@in_reply_to_status_id && @options.get_tweet? then
        @in_reply_to_status ||= @app.get_a_status(@in_reply_to_status_id)
        @in_reply_to_status ||= Tw::UnreadableTweet.new(@in_reply_to_status_id, Tw::NilUser({}))
      end
      return @in_reply_to_status
    end
    #---------------------------------------------------------------
    def has_in_reply_to_status?()
      return !!self.get_in_reply_to_status()
    end
    #---------------------------------------------------------------
    def url_to_tweet?(url)
      return url =~ /^https?:\/\/twitter.com\/[^\/]+\/status\/[0-9]+$/
    end
    #---------------------------------------------------------------
    def screen_name_in_url(url)
      return /^https?:\/\/twitter.com\/([^\/]+)\/status\/[0-9]+$/.match(url).to_a[1]
    end

    #---------------------------------------------------------
    # Twitter は、auto_populate_meta_data => true の場合、
    # ツイートに貼られた URL をたどり、その先の
    # ページに twitter:site 等の META タグがあれば、それを
    # 返信相手に勝手に加えてしまう。
    #
    # このメソッドは、ツイートに貼られたタグをたどり、
    # Twitter がリプ相手に勝手に加えてしまうユーザの
    # @screen_name またはユーザ ID を取得する。
    #---------------------------------------------------------
    def scrape_users(in_reply_to_status)
      user_arr = []
      return Tw::UserMentions.new(user_arr) if in_reply_to_status.nil?

      scraper = TwitterScraper.new()
      # ツイート中に含まれるリンクの先のウェブページに
      # 返信先が埋め込まれている場合。
      urls_arr = in_reply_to_status.entities.urls.to_a
      urls_arr.each do |url|
        if self.url_to_tweet?(url.expanded_url) then
          screen_name = self.screen_name_in_url(url.expanded_url)
          user_arr.push({:id => nil, :screen_name => screen_name})
          next
        end
=begin
        scraper.parse(url.expanded_url)
        if scraper.has_twitter_account? then
          site        = scraper.twitter_site
          screen_name = site[1, site.size - 1]  if !!site
          user_id     = scraper.twitter_site_id if !!scraper.twitter_site_id
          if !!screen_name && !!user_id then
            user_arr.push({:id => user_id, :screen_name => screen_name})
          else
            user = nil
            if !!screen_name && !user_id then
              user = screen_name
            elsif !screen_name && !!user_id then
              user = user_id
            end
            tw_user, last_update_time = @client.get_user_info(user, is_use_cache: false)
            user_arr.push({:id => tw_user.id, :screen_name => tw_user.screen_name})
          end
        end
=end
      end
      return Tw::UserMentions.new(user_arr)
    end

    #---------------------------------------------------------------
    # 新形式 auto_populate_reply において、返信先から外すユーザが
    # 指定されていた場合、それを返す。
    #---------------------------------------------------------------
    def get_exclude_screen_names()
      if self.auto_populate_reply? && self.has_in_reply_to_status? then
        scraped_users        = self.scrape_users(self.get_in_reply_to_status)
        exclude_screen_names = @update_options.set_exclude_reply_user_ids(
                                    @options.exclude_reply_user_ids,
                                    self.get_in_reply_to_status,
                                    scraped_users,
                                    is_exclude_scraped_users: true)
      else
        exclude_screen_names = []
      end
      return [scraped_users, exclude_screen_names]
    end

    #---------------------------------------------------------------
    # 意図しない形でリプを送らないように、ツイート文に含まれる
    # @screen_names とリプライ形式（新旧）との関係が適正かどうか
    # ユーザが確認できるように表示する。
    #---------------------------------------------------------------
    def warn_if_unsuitable_message_as_reply(message_to_post)
      ret = 0
      return ret if !self.has_in_reply_to_status?

      reply_checker = ReplyChecker.new(self.get_in_reply_to_status, message_to_post)
      if self.auto_populate_reply? then
        # 新しいリプ形式
        if reply_checker.message_has_screen_name_of_reply_poster? \
          || reply_checker.reply_has_screen_name_that_message_has? then
          @app.renderer.puts("WARNING: Duplication: #{reply_checker.screen_names_in_message.join(" ")}")
          ret = EXIT_BY_NO if !@app.prompt("Continue? (Y/N): ")
        end
      else
        # 古いリプ形式
        if reply_checker.reply_to_my_tweet? then # 自分のTWへ
          if reply_checker.reply_has_mentions_to_someone_else? then # 自分以外の@がある
            if reply_checker.message_has_mention_in_reply_target? then
            else
              ret = EXIT_BY_NO if !@app.prompt("WARNING: Anybody won't receive your old style reply. Continue? (Y/N): ")
            end
          end
        else # 他人のTWへ
          if !reply_checker.message_has_mention_in_reply_target? then
            ret = EXIT_BY_NO if !@app.prompt("WARNING: Anybody won't receive your old style reply. Continue? (Y/N): ")
          end
        end
      end
      return ret
    end

      #---------------------------------------------------------------
    public
      #---------------------------------------------------------------

    #---------------------------------------------------------------
    # ツイートを投稿する。
    #---------------------------------------------------------------
    def post()
      ret = 0

      message_to_post = MessageToPost.new(@app, @message)
      message_printer = MessagePrinter.new(@app, message_to_post, @options)
      message_printer.print_long_line()

      #---------------------------------------------------------
      # in_reopy_to で指定されたリプライの宛先のツイートを表示する。
      #---------------------------------------------------------
      if @options.get_tweet? then
        # リプライ先ツイートを取得する
        in_reply_to_status = self.get_in_reply_to_status()
        if !!in_reply_to_status then
          message_printer.display_reply_target_tweet(in_reply_to_status)
        end
      end

      #---------------------------------------------------------
      # ツイート文の長さを表示。
      # ツイート文が長すぎた場合はメソッドを抜ける。
      #---------------------------------------------------------
      message_printer.print_message_length()
      if !message_to_post.within_280_chars? then
        $stderr.puts("Message too long (#{message_to_post.shortened_length})")
        ret = 1
        return ret
      end
      #---------------------------------------------------------
      # 旧形式のリプを使うかどうか。
      #---------------------------------------------------------
      @update_options.disable_auto_populate_reply_metadata = !self.auto_populate_reply?
      #---------------------------------------------------------
      # 新形式のリプで、宛先から除外する除外するユーザを取得。
      #---------------------------------------------------------
      scraped_users, exclude_screen_names = self.get_exclude_screen_names()
      #---------------------------------------------------------
      # 新形式のリプ用の表示用メッセージを message_to_post に
      # セットする。
      ## NOTE: 要リファクタリング
      #---------------------------------------------------------
      message_to_post.build_text_for_display(
              self.get_in_reply_to_status, scraped_users,
              !self.auto_populate_reply?, exclude_screen_names)
      #---------------------------------------------------------
      # 送信するメッセージ（表示用）を表示する。
      # メディア・ファイルやビデオ・ファイルが指定されていれば
      # そのファイル名を表示。
      # NOTE: 要リファクタリング
      #---------------------------------------------------------
      message_printer.print_message_text()
      #---------------------------------------------------------
      # 添付するメディア（画像）ファイルのファイル名を取得して表示。
      # ファイルが存在しないなどの場合はメソッドを抜ける。
      #---------------------------------------------------------
      is_print_success = message_printer.check_and_print_media_file_names()
      if !is_print_success then
        ret = 1
        return ret
      end
      #---------------------------------------------------------
      # 添付する動画ファイルのファイル名を取得して表示。
      #---------------------------------------------------------
      is_print_success = message_printer.check_and_print_video_file_name()
      if !is_print_success then
        ret = 1
        return ret
      end
      #---------------------------------------------------------
      # 引用ツイートまたは DM deep link の URL を取得して表示。
      #---------------------------------------------------------
      quote_tweet_url = @options.quote_tweet_url()
      message_printer.print_quote_tweet_url()

      #---------------------------------------------------------
      # 除外するユーザの @名 を表示する。
      #---------------------------------------------------------
      message_printer.print_exclude_user_screen_names(exclude_screen_names)
      if exclude_screen_names.size > 0 then
        message_printer.print_long_line()
      end

      #---------------------------------------------------------
      # ツイートしている地点の地理情報を設定する。
      #---------------------------------------------------------
      if ENV["TWGEO"] || @options.geo? then
        geo = Tw::App::Geo.new(@client)
        self.update_options.merge!(geo.options_for_update())
        $stderr.puts(geo.location_string(:simple))
        message_printer.print_long_line()
      end

      #---------------------------------------------------------
      # 誰にも届かないリプ（普通のツイート）や、同じ @screen_nameが
      # 重なるような不注意リプにならないための確認画面を出す。
      #---------------------------------------------------------
      confirm_result = self.warn_if_unsuitable_message_as_reply(message_to_post)
      ret = confirm_result
      return ret if ret != 0

      #---------------------------------------------------------
      # Query if the user will tweet.
      #---------------------------------------------------------
      if !@options.assume_yes? then
        if !@app.prompt("Tweet it? (Y/N): ")
          ret = EXIT_BY_NO
          return ret if ret != 0
        end
      end

      #---------------------------------------------------------
      # Upload media files asynchronously.
      #---------------------------------------------------------
      if @options.media_ids? then
        # コマンドライン・オプションからアップロード済みの
        # media_id を取得
        @update_options.media_ids = @options.media_ids()
      elsif @options.media_file_names.size > 0 then
        # メディアをアップロードして media_id を取得する
        image_upload_options = {
            :media_category    => IMAGE_MEDIA_CATEGORY,
            :additional_owners => @app.get_additional_owners(),
        }
        media_ids = @app.upload_multiple_media(@options.media_file_names, image_upload_options)
        @update_options.media_ids = media_ids if !media_ids.nil?
      end

      #---------------------------------------------------------
      # Upload a video.
      #---------------------------------------------------------
      if !!@options.video_file_name() then
        additional_owners = nil
        upload_result = @app.upload_video(@options.video_file_name(),
                          VIDEO_MEDIA_TYPE, VIDEO_MEDIA_CATEGORY,
                          @app.get_additional_owners())
        video_id = upload_result[:media_id].to_s
        if !!video_id then
          if @update_options.media_ids? then
            @update_options.media_ids = tweet_poster.update_options.media_ids.split(',') \
                .push(video_id).join(',') 
          else
            @update_options.media_ids = video_id
          end
        end
      end

      #---------------------------------------------------------
      # Set the option for a quote tweet or a DM deep link.
      #---------------------------------------------------------
      if !!quote_tweet_url then
        @update_options.attachment_url = quote_tweet_url
      end

      #---------------------------------------------------------
      # Send a tweet actually.
      #---------------------------------------------------------
      result_hash_tweet = @client.tweet(message_to_post.text, @update_options.update_options)
      result_tweet = Tw::Tweet.compose(result_hash_tweet, @client.followers_ids_from_cache())

      #---------------------------------------------------------
      # Display the results of sending the tweet.
      #---------------------------------------------------------
      @app.renderer.puts(result_tweet.full_text.decode_html())
      @app.renderer.puts(result_tweet.url)
      @app.renderer.puts(result_tweet.created_at.localtime)

      return ret
    end
  end

end
