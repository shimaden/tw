# encoding: UTF-8
# このファイルはＵＴＦ－８です。
module Tw::App

  class Executor < AbstractExecutor
  #**************************************************************************
  #
  #                              Detectors
  #
  #**************************************************************************
    
    #----------------------------------------------------------------
    # Detect a user ID or a screen name in a string.
    # If the user_str is a user ID, return it as an Integer.
    # If the user_str is a screen name, return it in String with '@'.
    # If neither, return nil.
    #----------------------------------------------------------------
    def user_name_or_id(user_str)
      if user_str =~ /^[0-9]+$/ then
        user = Integer(user_str)               # user ID (Integer)
      elsif user_str =~ /^@[a-zA-Z0-9_]+$/ then
        user = user_str[1, user_str.length - 1]  # Screen name following with '@'
      else
        user = nil
      end
      return user
    end

    # @user1,1234,@user2,@user3,112
    def user_name_and_id_array(user_str)
      user_reg_str = '@[a-zA-Z0-9_]+|\d+'
      user_reg = /^(#{user_reg_str})(?:,(#{user_reg_str}))*$/
      return [] if !(user_reg =~ user_str)
      user_array = []
      user_str.gsub(/#{user_reg_str}/) do |user|
      #user_str.split(',') do |user|
        if user =~ /^\d+$/ then
          user_array.push(Integer(user))
        else
          user_array.push(user)
        end
      end
#$stderr.puts("#{user_array.inspect}")
      return user_array
    end

    #----------------------------------------------------------------
    # Convert a comma separated text into an array of Integer.
    # If an invalid value is contained in the str, it is ignored.
    #----------------------------------------------------------------
    def get_id_array(str)
      return [] if str.nil?
      if str =~ /^((\d+)(,\d+)*)?$/ then
        id_array = []
        str.split(',').each do |id|
          id_array.push(Integer(id))
        end
        return id_array
      else
        raise CmdOptionError.new("str must be string with CSV or nil but #{str.class}.")
      end
    end

  end

end
