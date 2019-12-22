# Reply formatter

module Tw::App

  class ReplyFormatter

    #----------------------------------------------------------------
    # Initializer
    #----------------------------------------------------------------
    def initialize(tweet, format, message, current_user_name, cc_mode)
      shEscSeq = Sh::Shell::ZshEscapeSequence.new(true)
      @tweet             = tweet
      @format            = format
      @message           = shEscSeq.append_escape_characters(message)
      @current_user_name = current_user_name
      @cc_mode           = cc_mode
    end

      #----------------------------------------------------------------
    protected
      #----------------------------------------------------------------

    def have_user_mentions?(tweet)
      return tweet.entities? && tweet.entities.user_mentions?
    end

    def get_to_user(sender, fmt = nil)
      if fmt == :array then
        to_user = (sender == @current_user_name) ? [] : ["@#{sender}"]
      else
        to_user = (sender == @current_user_name) ? "" : "@#{sender}"
      end
      return to_user
    end

    def get_cc_users(sender, user_mentions, fmt = nil)
      cc_users_arr = user_mentions.reject {|m|
            m.screen_name == sender || m.screen_name == @current_user_name}
        .collect {|m| "@#{m.screen_name}"}.uniq()
        .reject {|str| str.empty?}
      if fmt == :arr then
        cc_users = cc_users_arr
      else
        cc_users = cc_users_arr.join(" ")
      end
      return cc_users
    end

    def create_command_line(client, to_user, message, cc_users, in_reply_to, fmt = nil)
      if @cc_mode then
        arr = [to_user, message, cc_users].flatten()
      else
        arr = [to_user, cc_users, message].flatten()
      end

      body = arr.reject {|str| str.empty?}.join(" ")

      if fmt == :array then
        cmd_line = [client, body, in_reply_to].flatten()
      else
        cmd_line = "#{client} \"#{body}\" #{in_reply_to}"
      end
      return cmd_line
    end

      #----------------------------------------------------------------
    public
      #----------------------------------------------------------------

    #----------------------------------------------------------------
    # Build a text for a reply tweet.
    #----------------------------------------------------------------
    def build()
      sender = @tweet.user.screen_name
      client = "#{Tw::Conf::SOFTWARE_NAME}"
      in_reply_to = "-R #{@tweet.id}"

      if self.have_user_mentions?(@tweet) then
        if @format[:cmd_fmt] == Tw::App::Renderer::FMT_ARRAY then
          to_user  = self.get_to_user(sender, :array)
          cc_users = self.get_cc_users(
                              sender, @tweet.entities.user_mentions, :array)
          cmd_line = self.create_command_line(
                              client, to_user, @message, cc_users, in_reply_to,
                              :array)
        else
          to_user  = self.get_to_user(sender)
          cc_users = self.get_cc_users(sender, @tweet.entities.user_mentions)
          cmd_line = self.create_command_line(
                            client, to_user, @message, cc_users, in_reply_to)
        end
      else
        if @format[:cmd_fmt] == Tw::App::Renderer::FMT_ARRAY then
          cmd_line = [client, "@#{sender} #{@message}", in_reply_to]
        else
          cmd_line = "#{client} \"@#{sender} #{@message}\" #{in_reply_to}"
        end
      end

      return cmd_line
    end

  end

end
