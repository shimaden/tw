# encoding: UTF-8
# このファイルはＵＴＦ－８です。
require File.expand_path('../utility/cgi_escape', File.dirname(__FILE__))

module Smdn

  class UserIDsCursorError < ::StandardError
  end

  class UserIDsCursor
    attr_reader :ids, :next_cursor, :previous_cursor
    include Smdn::CGI
    MAX_COUNT = 5000

    def initialize(requester, user, options, request_interval)
      super()
      if !requester.is_a?(Tw::TwitterRequester) then
        raise ::TypeError.new("Use Tw::TwitterRequester instead of #{requester.class}.")
      end
      @requester        = requester
      @user             = user
      @options          = options
      @request_interval = request_interval
      @expire_time      = Time.now()
    end

    protected

    def do_get_entry_point()
    end
    def do_get_additional_options()
#      return {
#          :tweet_mode       => 'extended',
#          :include_entities => true,
#          :skip_status      => false,
#      }
      return {}
    end

    def log()
      $stderr.puts("next_cur: #{@next_cursor}, prev_cur: #{@previous_cursor}")
      $stderr.puts("amount: #{@users.size}")
    end

    def get_from_api()
      params = {:cursor => @cursor.to_s}
      params.merge!(self.do_get_additional_options())
      if @user.is_a?(Integer) then
        params[:user_id] = @user
      elsif @user.is_a?(String) then
        params[:screen_name] = @user
      end
      result = @requester.get(self.do_get_entry_point(), params)
      @users.concat(result[:ids])
      @next_cursor     = result[:next_cursor]
      @previous_cursor = result[:previous_cursor]
      @expire_time     = Time.now() + @request_interval
    end

    def get()
      if @expire_time < Time.now() then
        @cursor = -1
        @users = []
        @next_cursor = nil
        @previous_cursor = nil
        is_continue = true
        while is_continue do
          self.get_from_api()
          @cursor = @next_cursor
          is_continue = (@next_cursor > 0)
        end
      end
    end

    public

    def find(id)
      self.get()
      return @users.find(id)
    end

    def include?(id)
      self.get()
      return @users.include?(id)
    end

    def size()
      self.get()
      return @users.size()
    end

    def users()
      self.get()
      return @users
    end

  end

end
