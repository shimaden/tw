# encoding: UTF-8
# このファイルはＵＴＦ－８です。
require File.expand_path('user_ids_cursor', File.dirname(__FILE__))

module Tw

  class MutesIDsCursor < Smdn::UserIDsCursor
    HOUR        = 60 * 60

    def initialize(requester, options, request_interval = HOUR)
      user = nil
      super(requester, user, options, request_interval)
    end

    protected

    def do_get_entry_point()
      return '/1.1/mutes/users/ids.json'
    end
    def do_get_additional_options()
      return {}
    end

  end

end
