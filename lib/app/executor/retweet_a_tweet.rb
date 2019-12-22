# encoding: UTF-8
module Tw::App

  class Executor < AbstractExecutor

    protected

    #----------------------------------------------------------------
    # Retweet a tweet.
    #----------------------------------------------------------------
    def retweet_a_tweet(status_id)
      ret = nil

      if !(status_id.to_s =~ /^[0-9]+$/) then
        $stderr.puts("Status id must be an Integer.")
        return 1
      end

      begin
        self.client.new_auth(@account)
        id = Integer(status_id)
        reply_depth = 0
        user_info = nil
        #if !@options.dont_get_tweet? then
        if @options.get_tweet? then
          twTweet, exceptions = self.client.get_a_status(id, reply_depth, user_info)
          raise exceptions[0] if exceptions.size > 0
          if twTweet.nil? then
            $stderr.puts("Can't access the tweet \"#{id}\"")
            return 1
          end
          format = @options.format()
          if !( format[:data_fmt] == Tw::App::Renderer::FMT_TEXT \
             || format[:data_fmt] == Tw::App::Renderer::FMT_COLOR) then
            format[:data_fmt] = Tw::App::Renderer::FMT_TEXT
          end
          self.renderer.display([twTweet], format, separator: "", current_user_id: self.client.current_user_id)
        end

        if !@options.assume_yes? then
          if !self.prompt("Retweet it? (Y/N): ")
            return EXIT_BY_NO
          end
        end

        twReTweet = self.client.retweet(id)
        self.renderer.puts("Retweet succeeded.")
        self.renderer.display([twReTweet], @options.format(), separator: "", current_user_id: self.client.current_user_id)
        ret = 0
      rescue Tw::Error::Forbidden, Tw::Error::Unauthorized,
             Tw::Error::NotFound
        raise
      rescue => e
        ret = self.show_rescue(__FILE__, __LINE__, __method__, e,
                               {:status_id => id})
      end
      return ret
    end

    #----------------------------------------------------------------
    # Unretweet a tweet.
    #----------------------------------------------------------------
    def unretweet_a_tweet(status_id)
      ret = nil

      if !(status_id.to_s =~ /^[0-9]+$/) then
        $stderr.puts("Status id must be an Integer.")
        return 1
      end

      begin
        self.client.new_auth(@account)
        id = Integer(status_id)
        reply_depth = 0
        user_info = nil
        #if !@options.dont_get_tweet? then
        if @options.get_tweet? then
          twTweet, exceptions = self.client.get_a_status(id, reply_depth, user_info)
          raise exceptions[0] if exceptions.size > 0
          if twTweet.nil? then
            $stderr.puts("Can't access the tweet \"#{id}\"")
            return 1
          end
          format = @options.format()
          if !( format[:data_fmt] == Tw::App::Renderer::FMT_TEXT \
             || format[:data_fmt] == Tw::App::Renderer::FMT_COLOR) then
            format[:data_fmt] = Tw::App::Renderer::FMT_TEXT
          end
          self.renderer.display([twTweet], format, separator: "", current_user_id: self.client.current_user_id)
        end

        if !@options.assume_yes? then
          if !self.prompt("Retweet it? (Y/N): ")
            return EXIT_BY_NO
          end
        end

        twReTweet = self.client.unretweet(id)
        self.renderer.puts("Retweet succeeded.")
        self.renderer.display([twReTweet], @options.format(), separator: "", current_user_id: self.client.current_user_id)
        ret = 0
      rescue Tw::Error::Forbidden, Tw::Error::Unauthorized,
             Tw::Error::NotFound
        raise
      rescue => e
        ret = self.show_rescue(__FILE__, __LINE__, __method__, e,
                               {:status_id => id})
      end
      return ret
    end

  end

end
