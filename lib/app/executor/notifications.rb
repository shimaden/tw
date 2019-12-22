# encoding: UTF-8
# このファイルはＵＴＦ－８です。
module Tw::App

  class Executor < AbstractExecutor

    protected

    #----------------------------------------------------------------
    # Show notifications
    #----------------------------------------------------------------
    def notifications(optname, optarg)
      self.client.new_auth()
      options = {
        :count         => @options.count(),
        :since_id      => @options.since_id(),
        #:max_id        => @options.max_id(),
        #:reply_depth   => @options.reply_depth(),
      }

      hash = self.client.get_activity_about_me(options)
=begin
      ret_arr = []
      self.get_id_array(optarg).each do |id|
        tweet_arr = self.client.get_conversation(id)
        self.renderer.display(tweet_arr, @options.format(), separator: "\n", current_user_id: self.client.current_user_id)
      end
      ret = RetCode.new()
      ret.code = 0
      ret.add_sub_code(ret_arr)

      return ret
=end
      return 0
    end

  end

end
