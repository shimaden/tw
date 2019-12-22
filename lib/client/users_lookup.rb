# encoding: UTF-8
# このファイルはＵＴＦ－８です。
require File.expand_path('user_list_cursor', File.dirname(__FILE__))

module Tw

  class UsersLookup < Smdn::UserListCursor
    HOUR        = 60 * 60

    def initialize(requester, user_ids, screen_names, request_interval = HOUR)
      users = user_ids.concat(screen_names)
      super(requester, users, request_interval)
    end

    protected

    def do_get_entry_point()
      return '/1.1/users/lookup.json'
    end

  end

end


=begin
if $0 == __FILE__ then

  require File.expand_path('custom-connection', File.dirname(__FILE__))

  class Conn < Smdn::CustomConnection
    def access_token()
      super()
    end
  end

  conn = Conn.new()

  friends = Smdn::FriendsList.new(conn.access_token)

  puts("Size: #{friends.size()}")
  puts(friends.include?(1014958698))
  puts(friends.include?(314736798))
  puts(friends.include?(123))

  users = friends.users.reverse()
  users.each do |user|
    printf("%12d @%-15s %s\n", user[:id], user[:screen_name], user[:name])
  end
end
=end
