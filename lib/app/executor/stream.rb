# encoding: UTF-8
module Tw::App

    class Executor < AbstractExecutor

    protected

    #----------------------------------------------------------------
    # Display an object from the user stream.
    #----------------------------------------------------------------
    def display_stream_object(obj, current_user_id)
      separator     = "\n"
      dbl_separator = "\n\n"
      meth = __method__
      if obj.is_a?(Tw::Tweet) then
        lastTweet = obj
        self.renderer.display([obj], @options.format(),  separator: separator, current_user_id: current_user_id)
      elsif obj.is_a?(Tw::DMTweet) then
        self.renderer.display([obj], @options.format(), separator: separator, current_user_id: current_user_id)
      elsif obj.is_a?(Tw::Stream::Message) then
        self.renderer.display_stream_message(obj, @options.format, separator: separator)
      elsif obj.is_a?(Hash) && obj.size > 0 then
        if obj[:friends] then
          self.renderer.display_stream_message(obj, @options.format, separator: separator)
        else
          # Unknown data
          self.renderer.display_stream_message(obj, @options.format(), separator: separator)
        end
      else
        # do_nothing()
      end
    end

    #----------------------------------------------------------------
    # User stream (real time stream of home timeline)
    #----------------------------------------------------------------
    def stream(optname, optarg)
      new_auth = Tw::NewAuth.new(@account)
      new_auth.auth()
      requester = Tw::TwitterRequester.new(new_auth)
      followers_cache_option = {
        :permission => FOLLOWERS_CACHE_PERMISSON,
        :interval   => FOLLOWERS_CACHE_INTERVAL
      }
      stream    = Tw::Stream::Stream.new(requester, followers_cache_option)
      format    = @options.format()
      current_user_id = new_auth.user.id
      separator       = "\n"
      lastTweet       = nil
      is_disconnected = false
      $stderr.puts("-- waiting stream...")
      loop do
        begin
          stream.user_stream do |obj|
            if is_disconnected && lastTweet then
              # ここ以下は作り直した方がいいかも。
              # （ストリームが途切れたときに代わりに home timeline から取るの）
              #timeline = stream.home_timeline(lastTweet.id)
              #self.renderer.display(timeline, @options.format(), separator: separator, current_user_id: current_user_id)
              #self.logger.debug(
              #      "Tw::App::Executor.stream(): Timeline recovery completed.")
              is_disconnected = false
            end
            if obj.is_a?(Tw::Tweet) then
              lastTweet = obj
            end
            self.display_stream_object(obj, current_user_id)
          end
          ret = 0
        rescue EOFError, SocketError, Timeout::Error => e
          is_disconnected = true

          $stderr.puts(">>> #{e.class} (#{e.message})")
          $stderr.puts(">>> Retrying to connect to Twitter stream.")
          sleep(5)
          next
        rescue => e
          $stderr.puts(experr(__FILE__, __LINE__, e, "receiving user stream"))
          $stderr.puts(Tw::BACKTRACE_MSG)
          raise if ENV["TWBT"]
          ret = 1
        end
      end
      return ret
    end

    #----------------------------------------------------------------
    # User stream with tracking (real time stream of home timeline)
    #----------------------------------------------------------------
    def filter_stream(optname, optarg)
      is_include_retweets = false
      #is_include_retweets = true
      new_auth = self.client.new_auth()
      requester = Tw::TwitterRequester.new(new_auth)
      filter_options = {}
      if @options.filter_stream_follow? then
        filter_options[:follow] = @options.filter_stream_follow()
      end
      followers_cache_option = {
        :permission => FOLLOWERS_CACHE_PERMISSON,
        :interval   => FOLLOWERS_CACHE_INTERVAL
      }
      #friendsIds = self.client.friends_ids(followers_cache_option, new_auth.user_id)
      friendsIds = self.client.friends_ids(new_auth.user_id)
      stream    = Tw::Stream::Stream.new(requester, followers_cache_option)
      format    = @options.format()
      current_user_id = new_auth.user.id
      separator       = "\n"
      lastTweet       = nil
      is_disconnected = false
      $stderr.puts("-- waiting filter stream...")
      loop do
        begin
          stream.filter_stream(filter_options, friendsIds, is_include_retweets) do |obj|
            if is_disconnected && lastTweet then
              # ここ以下は作り直した方がいいかも。
              # （ストリームが途切れたときに代わりに home timeline から取るの）
              #timeline = stream.home_timeline(lastTweet.id)
              #self.renderer.display(timeline, @options.format(), separator: separator, current_user_id: current_user_id)
              #self.logger.debug(
              #      "Tw::App::Executor.stream(): Timeline recovery completed.")
              is_disconnected = false
            end
            if obj.is_a?(Tw::Tweet) then
              lastTweet = obj
            end
            self.display_stream_object(obj, current_user_id)
          end
          ret = 0
        rescue EOFError, SocketError, Timeout::Error => e
          is_disconnected = true

          $stderr.puts(">>> #{e.class} (#{e.message})")
          $stderr.puts(">>> Retrying to connect to Twitter stream.")
          sleep(5)
          next
        rescue => e
          $stderr.puts(experr(__FILE__, __LINE__, e, "receiving user stream"))
          $stderr.puts(Tw::BACKTRACE_MSG)
          raise if ENV["TWBT"]
          ret = 1
        end
      end
      return ret
    end

  end

end
