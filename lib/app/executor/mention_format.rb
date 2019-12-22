# encoding: UTF-8
module Tw::App

  class Executor < AbstractExecutor

    protected

    #----------------------------------------------------------------
    # Format a tweet text for mention.
    #----------------------------------------------------------------
    def mention_format(optname, optarg)
      ret = nil

      if !(optarg =~ /^[0-9]+$/) then
        $stderr.puts "Status id must be an integer."
        return 1
      end

      begin
        self.client.new_auth(@account)
        id = Integer(optarg)
        reply_depth = 0
        user_info = nil
        twTweet, exceptions = self.client.get_a_status(id, reply_depth, user_info)
        if exceptions.size > 0 then
          raise exceptions[0]
        end
        if twTweet.nil? then
          $stderr.puts "Can't access the tweet \"#{id}\""
          return 1
        end

        formatter = Tw::App::MentionFormatter.new(twTweet, @options.format())
        text = formatter.build()
        self.renderer.puts(text)

        ret = 0
      rescue Tw::Error::Unauthorized,
             Tw::Error::ServiceUnavailable,
             Tw::Error::RequestTimeout,
             Tw::Error::NotFound,
             Tw::App::AbstractExecutor::CmdOptionError
        raise
      rescue Tw::Error  => e
        $stderr.puts experr(__FILE__, __LINE__, e)
        ret = 1
      rescue => e
        $stderr.puts experr(__FILE__, __LINE__, e)
        $stderr.puts Tw::BACKTRACE_MSG
        $stderr.puts(e.backtrace.join("\n")) if ENV["TWBT"]
        ret = 1
      end
      return ret
    end

  end

end
