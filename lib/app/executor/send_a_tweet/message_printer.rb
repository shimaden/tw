# encoding: utf-8

module Tw::App

  #===========================================================
  # ツイート前にツイートするかどうかの確認メッセージを表示
  # する。
  # 画像や動画ファイルが指定されていればそのファイル名も表示
  # する。
  #===========================================================
  class MessagePrinter

    LONG_LINE  = 76
    SHORT_LINE = 68

    BLUE      = "\e[38;5;#{"4B".to_i(16)}m"
    YELLOW    = "\e[33m"
    UNDERLINE = "\e[4m"
    CLEAR     = "\e[0m"

    def initialize(app, message_to_post, options)
      @app                   = app
      @renderer              = @app.renderer
      @message_to_post       = message_to_post
      @options               = options
    end

    protected

    #---------------------------------------------------------------
    # n 個の '-' の線の文字列を返す。
    #---------------------------------------------------------------
    def line_str(n)
      return "-" * n
    end

    public

    #---------------------------------------------------------------
    # 長い線を表示する。
    #---------------------------------------------------------------
    def print_long_line()
      @renderer.puts(self.line_str(LONG_LINE))
    end

    #---------------------------------------------------------------
    # リプライ対象のツイートを表示
    #---------------------------------------------------------------
    def display_reply_target_tweet(in_reply_to_status)
      if in_reply_to_status.is_a?(Tw::UnreadableTweet) then
        # リプライ先ツイートが取得できてない
        @renderer.puts("Reply-to: #{in_reply_to_status_id} (UNACCESSIBLE)")
        in_reply_to_status_arr = []
      else
        # リプライ先ツイートが取得できている
        @renderer.puts("Reply-to: #{in_reply_to_status.id}")
        in_reply_to_status_arr = [in_reply_to_status]
      end
      # リプライ先ツイートを表示する。
      @app.status(nil, in_reply_to_status.id,
                    ignore_unauthorized_exception: true,
                    status_arr: in_reply_to_status_arr)
      @renderer.puts(self.line_str(SHORT_LINE))
    end

    #---------------------------------------------------------------
    # 送信文の文字数を表示する。
    #---------------------------------------------------------------
    def print_message_length()
      shortened_length = @message_to_post.shortened_length
      max_tweet_length = @message_to_post.max_tweet_length
      @renderer.puts("Length: #{shortened_length} " \
                         "remain: #{max_tweet_length - shortened_length} " \
                         "(Orig: #{@message_to_post.text.length})")
    end

    #---------------------------------------------------------
    # Print the message text for display.
    #---------------------------------------------------------
    def print_message_text()
      @renderer.puts("Msg: #{@message_to_post.text_for_display}")
    end

    #---------------------------------------------------------
    # Print exclude user screen names.
    #---------------------------------------------------------
    def print_exclude_user_screen_names(exclude_screen_names)
      return if exclude_screen_names.size == 0
      text = exclude_screen_names.join(', ')
      @renderer.puts("[EXCLUDE] #{text}")
    end

    #---------------------------------------------------------
    # Display media file names if specified.
    #---------------------------------------------------------
    def check_and_print_media_file_names()
      is_success = true
      if @options.media_file_names.size > 0 then
        @options.media_file_names.each.with_index(1) do |fname, i|
          @renderer.print("Media[#{i}]: #{fname}")
          if FileTest.exist?(fname) then
            @renderer.print("\n")
          else
            @renderer.print(": does not exist.\n")
            is_success = false
          end
        end
      end
      return is_success
    end

    #---------------------------------------------------------
    # Display a video file name if specified.
    #---------------------------------------------------------
    def check_and_print_video_file_name()
      is_success = true
      video_file_name = @options.video_file_name()
      if !!video_file_name then
        @renderer.print("Video: #{video_file_name}")
        if FileTest.exist?(video_file_name) then
          @renderer.print("\n")
        else
          @renderer.print(": does not exist.\n")
          is_success = false
        end
      end
      return is_success
    end

    #---------------------------------------------------------
    # Display a URL of a quote tweet or a DM deep link.
    #---------------------------------------------------------
    def print_quote_tweet_url()
      if !!@options.quote_tweet_url then
        @renderer.puts("Quote: #{@options.quote_tweet_url}")
      end
    end

  end

end
