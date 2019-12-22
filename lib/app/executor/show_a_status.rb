# encoding: UTF-8
# このファイルはＵＴＦ－８です。
module Tw::App

  class Executor < AbstractExecutor

    protected

    #----------------------------------------------------------------
    # Show a status (tweet).
    #----------------------------------------------------------------
    def show_a_status(twTweet)
      if !twTweet.is_a?(Tw::Tweet) then
        raise ::TypeError.new("twTweet must be Tw::Tweet but #{twTweet.class}")
      end

      ret = nil
      begin
        self.renderer.display([twTweet], @options.format(), separator: "\n", current_user_id: self.client.current_user_id)
        ret = 0
      #rescue Errno::EPIPE
      rescue SystemCallError
        raise
      rescue ::TypeError
        raise
      rescue => e
        $stderr.puts(experr(__FILE__, __LINE__, e))
        $stderr.puts(Tw::BACKTRACE_MSG)
        $stderr.puts(e.backtrace) if ENV["TWBT"]
        ret = 1
      end

      return ret
    end

  end

end
