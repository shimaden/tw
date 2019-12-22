# encoding: UTF-8
# このファイルはＵＴＦ－８です。

require File.expand_path('tweet_poster', File.dirname(__FILE__))

module Tw::App
  class Executor < AbstractExecutor

    protected

    #----------------------------------------------------------------
    # メッセージをツイートする。
    # Tweet a message.
    #----------------------------------------------------------------
    def send_a_tweet(message, in_reply_to_status_id, is_auto_populate_reply)
      if !(in_reply_to_status_id.is_a?(Integer) || in_reply_to_status_id.nil?) then
        raise ::TypeError.new("in_reply_to_status_id must be an Integer or nil value but " \
          + "#{in_reply_to_status_id.class}.")
      end

      ret = nil
      begin
        self.client.new_auth(@account)
        tweet_poster = TweetPoster.new(self, message, in_reply_to_status_id,
                                       is_auto_populate_reply, @options)
        ret = tweet_poster.post()

      rescue Tw::Error::Unauthorized, Net::OpenTimeout
        raise
      rescue Tw::Error::VideoUploadError => e
        $stderr.puts("#{e.message}")
        ret = 1
      rescue Tw::Error::NotFound,
             Tw::Error::Forbidden,
             Tw::Error::BadRequest => e
        $stderr.puts("#{e.class}: #{e.code} #{e.message}")
        ret = 1
      rescue Tw::Error::ServiceUnavailable,
             Tw::Error::RequestTimeout,
             Tw::Error::AlreadyPosted,
             Tw::Error::InternalServerError,
             Tw::Error::DuplicateStatus => e
        $stderr.puts("#{e.code} #{e.message}")
        ret = 1
      rescue Tw::Error  => e
        $stderr.puts(experr(__FILE__, __LINE__, e))
        $stderr.puts(e.backtrace.join("\n")) if ENV["TWBT"]
        ret = 1
      rescue Errno::ENOENT => e  # ここは SystemCallError に置き換えない
        $stderr.puts(e.message)
        ret = NO_SUCH_FILE_OR_DIR
      rescue SystemCallError  # Errno::EHOSTUNREACH など Errno:: で始まる例外
        raise
      rescue => e
        $stderr.puts(experr(__FILE__, __LINE__, e))
        $stderr.puts(Tw::BACKTRACE_MSG)
        $stderr.puts(e.backtrace.join("\n")) if ENV["TWBT"]
        ret = 1
      end

      return ret
    end

  end

end
