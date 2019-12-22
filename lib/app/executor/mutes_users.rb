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
    # Get array of mutes user objects.
    #----------------------------------------------------------------
    def mutes_users(optname, optarg)
      ret = nil

      begin
        self.client.new_auth(@account)
        mutes_users = self.client.mutes_ids()
        twUsers = self.client.users_lookup(mutes_users, is_use_cache: true)
        format = @options.format()

        if @options.save_as_json().nil? then
          self.renderer.display(twUsers, format, separator: "", current_user_id: self.client.current_user_id)
        else
          fs = FileSaver.create(@options.save_as_json(), "w", :json)
          fs.save(twUsers)
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

    #----------------------------------------------------------------
    # Get array of IDs of mutes users.
    #----------------------------------------------------------------
    def mutes_users_ids(optname, optarg)
      ret = nil

      begin
        self.client.new_auth(@account)
        user_ids_arr = self.client.mutes_ids()
        format = @options.format()

        if !!@options.save_as_json? then
          fs = FileSaver.create(@options.save_as_json(), "w", :json)
          fs.save([{:friends => user_ids_arr}])
        elsif format[:data_fmt] == Tw::App::Renderer::FMT_JSON then
          self.renderer.puts({:friends => user_ids_arr}.to_json)
        elsif format[:data_fmt] == Tw::App::Renderer::FMT_CSV then
          self.renderer.puts({:friends => user_ids_arr}.to_json)
        else
          self.renderer.puts(user_ids_arr)
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
