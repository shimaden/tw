# encoding: utf-8

module Tw
  module App; end
end

module Tw::App

  class Executor < AbstractExecutor

    #---------------------------------------------------------
    # Additional owners
    #---------------------------------------------------------
    def get_additional_owners()
      return nil if !@options.additional_owners?

      result = nil
      user_id_arr = []
      @options.additional_owners.each do |user|
        if user =~ /^[0-9]+$/ then
          user_id_arr.push(Integer(user))
        elsif @options.validate_screen_name?(user) then
          twUser, cache_time = client.get_user_info(user, is_use_cache: true)
          user_id_arr.push(twUser.id)
        else
          raise ::RuntimeError.new("Program must not come here.")
        end
        result = user_id_arr.join(',') if user_id_arr.size > 0
      end
      return result
    end

  end

end
