# encoding: UTF-8
# このファイルはＵＴＦ－８です。
module Tw::App

  class Executor < AbstractExecutor

    protected

  #**************************************************************************
  #
  #                        Blocks User Objects
  #
  #**************************************************************************

    #----------------------------------------------------------------
    # Get array of blocks user objects.
    #----------------------------------------------------------------
    def blocks_users(optname, optarg)
      ret = nil

      begin
        self.client.new_auth(@account)
        blocks_users = self.client.blocks_ids()
        twUsers = self.client.users_lookup(blocks_users, is_use_cache: true)
        format = @options.format()

        if !@options.save_as_json? then
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
    # Get array of IDs of blocks users.
    #----------------------------------------------------------------
    def blocks_users_ids(optname, optarg)
      ret = nil

      begin
        self.client.new_auth(@account)
        user_ids_arr = self.client.blocks_ids()
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
