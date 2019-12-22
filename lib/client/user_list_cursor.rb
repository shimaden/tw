# encoding: UTF-8
# このファイルはＵＴＦ－８です。
require File.expand_path('../utility/cgi_escape', File.dirname(__FILE__))

module Smdn

  class UserListCursorError < ::StandardError
  end

  class UserListCursor
    attr_reader :ids, :next_cursor, :previous_cursor
    include Smdn::CGI
    MAX_COUNT = 100

    def initialize(requester, users, request_interval)
      super()
      @requester         = requester
      @user_id_array     = users.select{|u| u.is_a?(Integer)}
      @screen_name_array = users.select{|u| u.is_a?(String)}
      @user_array        = @user_id_array.concat(@screen_name_array)
      @request_interval  = request_interval
      @expire_time       = Time.now()
      @result_users      = []
    end

    protected

    def do_get_entry_point()
    end

    def log()
    end

    def get_from_api(id_csv, screen_name_csv)
      params = {}
      if screen_name_csv != nil && screen_name_csv.length > 0 then
        params[:screen_name]    = screen_name_csv
      end
      if id_csv != nil && id_csv.length > 0 then
        params[:user_id]        = id_csv
      end
      params[:include_entities] = true
      params[:tweet_mode]       = 'extended'

      url = self.do_get_entry_point()
      json = @requester.post(url, params)

      @expire_time = Time.now() + @request_interval
      return json
    end

    # 要求された @ids
    def get_times_to_call(user)
      times = user.size / MAX_COUNT
      times += 1 if user.size % MAX_COUNT > 0
      return times
    end

    def get()
      times = self.get_times_to_call(@user_array)
      user_list_array = []
      (0..(times - 1)).each do |i|
        user_list_array.push(@user_array[i * MAX_COUNT, MAX_COUNT])
      end

      user_array = []
      user_list_array.each do |user_list|
        id_array = user_list.select{|user| user.is_a?(Integer)}
        screen_name_array = user_list.select{|user| user.is_a?(String)}
        id_csv = id_array.join(',')
        screen_name_csv = screen_name_array.join(',')
        user_array.concat(self.get_from_api(id_csv, screen_name_csv))
      end

      user_array.each do |u|
        @result_users.push(Tw::User.compose(u, false))
      end

      return
    end

    public

    # user_id で示されるユーザが、返す Tweet のユーザを
    # フォローしているかどうかに使う。
    def users()
      self.get()
      return @result_users
    end

  end

end
