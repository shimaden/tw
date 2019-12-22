# encoding: UTF-8
module Tw::App

  class Executor < AbstractExecutor

    protected

  #**************************************************************************
  #
  #                         Direct Message Handler
  #
  #**************************************************************************

    #----------------------------------------------------------------
    # Read direct messages.
    #----------------------------------------------------------------
    def direct_messages(optname, optarg)
      ret = nil
      begin
        self.client.new_auth(@account)
        received_dm_array = self.client.direct_messages_received(@options.count())
        sent_dm_array     = self.client.direct_messages_sent(@options.count())
        # DM の表示順は display() メソッド内で、ID でソートされる。
        dm_array = received_dm_array + sent_dm_array
        self.renderer.display(dm_array, @options.format(), separator: "\n", current_user_id: self.client.current_user_id)
        ret = 0
      rescue => e
        $stderr.puts experr(__FILE__, __LINE__, e, "in receiving direct messages")
        $stderr.puts Tw::BACKTRACE_MSG
        raise if ENV["TWBT"]
        ret = 1
      end
      return ret
    end

    #----------------------------------------------------------------
    # Send a direct message.
    #----------------------------------------------------------------
    def direct_message_to(optname, optarg)
      ret = nil
      text = nil
      user = self.user_name_or_id(optarg)
      if user.nil? then
        $stderr.puts "user must be a user-id/@screen_name"
        return 1
      end

      if ARGV.size > 0 then
        text = ARGV[0]
      else
        $stderr.puts "Error: Message is required."
        return 1
      end

      long_line  = 76
      short_line = 68
      begin
        self.renderer.puts(self.line_str(long_line))
        self.renderer.puts("To : #{user}")
        self.renderer.puts("Msg: #{text}")

        if !@options.assume_yes? then
          if !self.prompt("Send the direct message? (Y/N): ")
            return EXIT_BY_NO
          end
        end

        self.client.new_auth(@account)
        self.client.create_direct_message(
                          user, text, self.followers_cache_option())
        ret = 0
      rescue => e
        $stderr.puts experr(__FILE__, __LINE__, e, "sending direct message")
        $stderr.puts Tw::BACKTRACE_MSG
        raise if ENV["TWBT"]
        ret = 1
      end
      return ret
    end

  end

end
