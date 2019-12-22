# encoding: UTF-8
# このファイルはＵＴＦ－８です。

module Tw::App

  #================================================================
  # MessageToPost
  #   投稿するためのメッセージを表すクラス
  #================================================================
  class MessageToPost
    attr_reader :text, :text_for_display,
                :poster_user_id, :poster_screen_name,
                :screen_names_in_text, :shortened_length,
                :max_tweet_length

    SCREEN_NAME_REG = /((?<![a-zA-Z0-9_\!#$%&@\*])@[a-zA-Z0-9_]+)/i
    MAX_TWEET_LENGTH = 280

    BLUE      = "\e[38;5;#{"4B".to_i(16)}m"
    YELLOW    = "\e[33m"
    UNDERLINE = "\e[4m"
    CLEAR     = "\e[0m"

    class ReplyToUser
      attr_reader :id, :screen_name
      def initialize(user, is_scribed = false)
        @id          = user.id
        @screen_name = user.screen_name
        @is_scribed  = !!is_scribed
      end
      public
      def scribed?()
        return @is_scribed
      end
    end

    #---------------------------------------------------------
    # イニシャライザー
    #---------------------------------------------------------
    def initialize(app, text)
      @client              = app.client
      @text                = text
      @poster_user_id      = app.client.new_auth.user_id
      @poster_screen_name  = app.client.new_auth.screen_name
      @screen_names_in_text = @text.gsub(SCREEN_NAME_REG).inject([]){|arr, sname|
        arr << sname
        arr
      }
      #weightened_length = @client.weightened_message_length(@text)
      #length_to_shorten_message = @client.length_to_shorten_message(@text, app.help_configuration_options())
      #length_to_shorten_message = @client.weightened_length_to_shorten_message_(@text, app.help_configuration_options())
      weightened_length = @client.weightened_length_to_shorten_message(@text, app.help_configuration_options())
      #@shortened_length = weightened_length - length_to_shorten_message
      @shortened_length = weightened_length
$stderr.puts("@shortened_length: #{@shortened_length}")
      @max_tweet_length = MAX_TWEET_LENGTH
    end

    protected

    #---------------------------------------------------------
    # 標準出力が端末に接続されているかを検査する。
    #---------------------------------------------------------
    def stdout_to_console?
      return !($stdout.stat.file? || $stdout.stat.pipe?)
    end

    #---------------------------------------------------------
    # 1 つの @screen_name に色をつける
    #---------------------------------------------------------
    def color_screen_name(screen_name, scribed)
      if self.stdout_to_console? then
        if scribed then
          return YELLOW + UNDERLINE + screen_name + CLEAR
        else
          return BLUE + UNDERLINE + screen_name + CLEAR
        end
      else
        return screen_name
      end
    end

    #---------------------------------------------------------
    # 表示用に、宛先となるユーザーの @mentions を格納した配列を返す。
    #---------------------------------------------------------
    def dest_users(in_reply_to_status, is_old_style_reply, scraped_users)
      dest_users_array = []
      # 返信先ツイートが自分のツイートでない場合、
      # そのツイートを発信した人の @名 を先頭に追加する。
      if in_reply_to_status.user.id != @client.new_auth.user_id then
        dest_users_array.push(ReplyToUser.new(in_reply_to_status.user))
      end

      # リプするツイートの返信先 @名 を配列に入れる。
      if in_reply_to_status.entities.user_mentions? then
        in_reply_to_status.entities.user_mentions.each do |um|
          if um.id != @client.new_auth.user_id && um.id != in_reply_to_status.user.id then
            dest_users_array.push(ReplyToUser.new(um))
          end
        end
      end

      # ツイート中に含まれるリンクの先のウェブページに
      # 返信先が埋め込まれている場合。
      if !is_old_style_reply then
        scraped_users.to_a.each do |um|
          is_scribed = true
          dest_users_array.push(ReplyToUser.new(um, is_scribed))
        end
      end

      return dest_users_array
    end

    public

    #---------------------------------------------------------------
    # 送信文の長さが 280 文字以内か
    #---------------------------------------------------------------
    def within_280_chars?()
      is_correct_length = true
      if @shortened_length > MAX_TWEET_LENGTH then
        is_correct_length = false
      end
      return is_correct_length
    end

    #---------------------------------------------------------
    # 表示用のメッセージ文字列を作成する。
    #---------------------------------------------------------
    def build_text_for_display(
            in_reply_to_status, scraped_users,
            is_old_style_reply, exclude_screen_names)

      # in_reply_to_status リプライ先のツイートがある場合
      # 返信相手の @screen_name を返信の本文（旧形式リプ）
      # またはツイート・オプションに含める（新形式リプ）
      if !!in_reply_to_status then
        dest_users_array = self.dest_users(in_reply_to_status, is_old_style_reply, scraped_users)

        if is_old_style_reply && !!in_reply_to_status then
          prefix = "[OLD STYLE REPLY] "
        else
          dest_users = ""
          dest_users_array.each do |user|
            next if exclude_screen_names.include?("@#{user.screen_name}")
            screen_name = self.color_screen_name("@#{user.screen_name}", user.scribed?)
            if dest_users == "" then
              dest_users += "#{screen_name}"
            else
              dest_users += ", #{screen_name}"
            end
          end
          prefix = dest_users.size > 0 ? "{#{dest_users}} " : ""
        end
      end

      @text_for_display = "#{prefix}\n#{@text}"
    end

  end
end
