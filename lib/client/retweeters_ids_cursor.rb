# encoding: UTF-8
# このファイルはＵＴＦ－８です。
require File.expand_path('user_ids_cursor', File.dirname(__FILE__))

module Tw

  class RetweetersIDsCursor < Smdn::UserIDsCursor
    HOUR        = 60 * 60

    def initialize(requester, status_id, options, request_interval = HOUR)
      @status_id = status_id # Only used in this class.
      user = nil
      super(requester, user, options, request_interval)
    end

    protected

    def do_get_entry_point()
      return '/1.1/statuses/retweeters/ids.json'
    end
    def do_get_additional_options()
      return {:id => @status_id, :stringify_ids => false}
    end

  end

end
