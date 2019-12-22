# encoding: UTF-8
# このファイルはＵＴＦ－８です。
module Tw::App

  class Executor < AbstractExecutor

    protected

    #----------------------------------------------------------------
    # Show conversation
    #----------------------------------------------------------------
    def conversation(optname, optarg)
      #self.logger.debug("Enter: Tw::App::Executor.conversation()")

      self.client.new_auth()
      ret_arr = []
      self.get_id_array(optarg).each do |id|
        tweet_arr = self.client.get_conversation(id)
        self.renderer.display(tweet_arr, @options.format(), separator: "\n", current_user_id: self.client.current_user_id)
      end
      ret = RetCode.new()
      ret.code = 0
      ret.add_sub_code(ret_arr)

      #self.logger.debug("Exit : Tw::App::Executor.conversation(): " \
      #                 "Status: #{ret}")

      return ret
    end

  end

end
