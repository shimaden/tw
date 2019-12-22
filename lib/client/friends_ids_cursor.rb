# encoding: UTF-8
# このファイルはＵＴＦ－８です。
require File.expand_path('user_ids_cursor', File.dirname(__FILE__))

module Tw

  class FriendsIDsCursor < Smdn::UserIDsCursor
    HOUR        = 60 * 60

    def initialize(requester, user, options, request_interval = HOUR)
      super(requester, user, options, request_interval)
    end

    protected

    def do_get_entry_point()
      return '/1.1/friends/ids.json'
    end

  end

end
