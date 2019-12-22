# encoding: UTF-8
module Tw::App

  class Executor < AbstractExecutor

    protected

  #**************************************************************************
  #
  #                        User Information Handler
  #
  #**************************************************************************

    #----------------------------------------------------------------
    # Show information of a user.
    #----------------------------------------------------------------
    def user_single(optname, optarg)
      ret = nil
      user = self.user_name_or_id(optarg)
      is_use_followers_ids_cache = @options.from_cache?
      if user.nil? then
        $stderr.puts("user must be a user-id|@screen_name")
        return 1
      end

      begin
        self.client.new_auth(@account)
        twUser, last_update_time = self.client.get_user_info(
                                          user,
                                          is_use_cache: is_use_followers_ids_cache
                                   )
        format = @options.format()
        opts = {:last_update_time => last_update_time}
        self.renderer.display([twUser], format,
                              separator: "",
                              current_user_id: self.client.current_user_id,
                              options: opts
        )
        ret = 0
      rescue Tw::Error::Unauthorized,
             Tw::Error::RequestTimeout,
             Tw::Error::Forbidden,
             Tw::Error::NotFound,
             Tw::Error::InternalServerError,
             Tw::Error::ServiceUnavailable
        raise
      rescue => e
        ret = self.show_rescue(__FILE__, __LINE__, __method__, e, {:user => user})
      end
      return ret
    end

    #----------------------------------------------------------------
    # Show information of a user.
    #----------------------------------------------------------------
    def user(optname, optarg)
      #ret = RetCode.new()
      #result = []
      ret = nil
      user_array = self.user_name_and_id_array(optarg)
      if user_array.nil? then
        $stderr.puts("user must be a comma separated repetetion of user-id|@screen_name")
        return 1
      end
      is_use_cache = @options.from_cache?
      fmt_user_array = user_array.map{|u| (u.is_a?(String) && u =~ /^@[a-zA-Z0-9_]+$/) ? u[1..(u.length - 1)] : u}

      self.client.new_auth(@account)
      begin
        users, last_update_time = self.client.users_lookup_ex(fmt_user_array, is_use_cache: is_use_cache)

        format = @options.format()
        opts = {:last_update_time => last_update_time}
        self.renderer.display(users, format,
                                separator: "",
                                current_user_id: self.client.current_user_id,
                                options: opts
        )
        #result << 0
        ret = 0
      rescue Tw::Error::Unauthorized,
             Tw::Error::RequestTimeout,
             Tw::Error::Forbidden,
             Tw::Error::NotFound,
             Tw::Error::InternalServerError,
             Tw::Error::ServiceUnavailable
        raise
      #rescue => e
      #  $stderr.puts("Error: #{e.class} #{e.message}")
      #  e.backtrace.each do |bt|
      #    $stderr.puts(bt)
      #  end
      #  result << 1
      #end
      rescue => e
        ret = self.show_rescue(__FILE__, __LINE__, __method__, e, {:user => user})
      end

      #if result.size == 1 then
      #  ret.code = result[0]
      #elsif result.size >= 2 then
      #  ret.add_sub_code(result)
      #end

      return ret
    end

  end

end
