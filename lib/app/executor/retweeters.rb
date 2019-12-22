# encoding: UTF-8
# このファイルはＵＴＦ－８です。
module Tw::App

  class Executor < AbstractExecutor

    protected

  #**************************************************************************
  #
  #                        Mutes Users Objects
  #
  #**************************************************************************

    #----------------------------------------------------------------
    # Get array of blocks user objects.
    #----------------------------------------------------------------
    def retweeters(optname, optarg)
      ret = nil
      reply_depth = 0
      user_info = nil
      if optarg =~ /^[0-9]+$/ then
        status_id = Integer(optarg)
      else
        raise ::ArgumentError.new("optarg must be a number in String.")
      end

      begin
        self.client.new_auth(@account)
        tweet, exceptions = self.client.get_a_status(status_id, reply_depth, user_info)
        retweeters_id = self.client.retweeters_ids(status_id)
        retweeters = self.client.users_lookup(retweeters_id, is_use_cache: true)
        format = @options.format()
        format = {
            :data_fmt => Tw::App::Renderer::FMT_SIMPLE,
            :cmd_fmt  => Tw::App::Renderer::FMT_NONE
        } # 暫定措置

        if @options.save_as_json().nil? then
          self.renderer.display(retweeters, format, separator: "", current_user_id: self.client.current_user_id)
          self.renderer.puts("#{retweeters.size} of #{tweet.retweet_count} retweeters.")
        else
          fs = FileSaver.create(@options.save_as_json(), "w", :json)
          fs.save(retweeters)
        end

        ret = 0
      rescue Tw::Error
        raise
      rescue SystemCallError
        raise
      rescue => e
        ret = self.show_rescue(__FILE__, __LINE__, __method__, e)
      end
      return ret
    end

  end

end
