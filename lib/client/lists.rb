# encoding: UTF-8
require File.expand_path('container/list', File.dirname(__FILE__))
require File.expand_path('../utility/cgi_escape', File.dirname(__FILE__))

module Tw

  #------------------------------------------------------------------
  # AbstractListCollection class
  #------------------------------------------------------------------
  class AbstractListCollection
    include Smdn::CGI
    attr_reader :exception
    MAX_COUNT_PER_REQUEST = 1000

    def initialize(requester, user)
      @requester = requester
      @options = { }

      if user =~ /^\d+$/ then
        @options[:user_id] = user
      elsif user.is_a?(String) then
        @options[:screen_name] = user
      else
        raise TypeError.new(blderr(__FILE__, __LINE__,
              "user must be one of an Integer and a String but " \
              "#{user.class} is given."))
      end
      @options[:count] = MAX_COUNT_PER_REQUEST
      @options[:cursor] = -1
    end

    def perform()
      begin
        @options[:cursor] = -1
        @list_array = [ ]

        is_quit = false
        while !is_quit do
          result = self.do_get_list(@options)
          followed_by = false
          @list_array.concat(
              result[:lists].collect {|list| Tw::List.new(list, followed_by)}
          )
          @options[:cursor] = result[:next_cursor]
          is_quit =(@options[:cursor] == 0) ? true : false
        end
      rescue Twr::Error::ServiceUnavailable => e
        @exception = e
      end
    end

    def get()
      return @list_array
    end
  end

  #------------------------------------------------------------------
  # ListsOwnership class
  # Get the lists the specified user have created.
  # 指定したユーザーが所有するリストの一覧
  # GET lists/ownerships
  # https://dev.twitter.com/docs/api/1.1/get/lists/ownerships
  #------------------------------------------------------------------
  class ListsOwnership < Tw::AbstractListCollection
    END_POINT = '/1.1/lists/ownerships.json'
    protected
    def do_get_list(options)
      hash = @requester.get(END_POINT, options)
      return hash
    end
  end

  #------------------------------------------------------------------
  # ListsMembership class
  # Get the lists the specified user has been added to.
  # 指定したユーザーがメンバーとなっているリストの一覧
  # GET lists/memberships
  # https://dev.twitter.com/docs/api/1.1/get/lists/memberships
  #------------------------------------------------------------------
  class ListsMemberships < Tw::AbstractListCollection
    END_POINT = '/1.1/lists/memberships.json'
    protected
    def do_get_list(options)
      hash = @requester.get(END_POINT, options)
      return hash
    end
  end

  #------------------------------------------------------------------
  # ListMembers class
  # Returns the members of the specified list. Private list members
  # will only be shown if the authenticated user owns the specified
  # list.
  # GET lists/members
  # https://api.twitter.com/1.1/lists/members.json
  #------------------------------------------------------------------
  class ListsMembers
    END_POINT = '/1.1/lists/members.json'

    # list_id または、slug と owner_screen_name もしくは owner_id で
    # リストを特定する。 
    def initialize(requester, followers, options)
      @requester = requester
      @followers = followers
      @options   = options
      @options[:cursor]  = !!options[:cursor] ? options[:cursor] : -1
      @options[:count]   = !!options[:count] ? options[:count] : 20   # with a maximum of 5000.
      @options[:include_entities] = !!options[:include_entities] ? options[:include_entities] : true
      @options[:skip_status] = !!options[:skip_status] ? options[:skip_status] : false
    end

    #-----------------------
    # 取得する
    #-----------------------
    def get()
      @user_arr = []
      is_continue = true
      while is_continue do
        hash = @requester.get(END_POINT, @options)
        @previous_cursor = hash[:previous_cursor]
        @next_cursor     = hash[:next_cursor]
        @user_arr.concat(hash[:users])
        is_continue = (@next_cursor > 0) && (@user_arr.size < @options[:count])
        @options[:cursor] = @next_cursor
      end
      member_users = @user_arr.map{|user|
                        Tw::User.compose(user, @followers.followed_by?(user[:id]))}
      return member_users
    end
  end


  #------------------------------------------------------------------
  # リストにメンバーを加えたり外したり
  #------------------------------------------------------------------
  class CustomListMember

    def initialize(requester, followers, list, user, owner)
      @requester = requester
      @followers = followers
      @options = {}

      if list =~ /^\d+$/ then
        @options[:list_id] = Integer(list)
      elsif list.is_a?(String) then
        @options[:slug] = list
      else
        raise TypeError.new(blderr(__FILE__, __LINE__,
              "list must be one of an Integer and a String but " \
              "#{list.class} is given."))
      end

      if user =~ /^\d+$/ then
        @options[:user_id] = Integer(user)
      elsif user.is_a?(String) then
        @options[:screen_name] = user
      else
        raise TypeError.new(blderr(__FILE__, __LINE__,
              "user must be one of an Integer and a String but " \
              "#{user.class} is given."))
      end
$stderr.puts("user: #{user.inspect}")

      if @options.has_key?(:slug) then
        if owner =~ /^\d+$/ then
          @options[:owner_id] = Integer(owner)
        elsif owner.is_a?(String) then
          @options[:owner_screen_name] = owner
        else
          raise TypeError.new(blderr(__FILE__, __LINE__,
                "owner must be one of an Integer or a String but " \
                "#{owner.class} is given."))
        end
      end
    end
  end


  #------------------------------------------------------------------
  # リストにメンバーを加える（1人だけバージョン）
  # https://dev.twitter.com/rest/reference/post/lists/members/create
  #------------------------------------------------------------------
  class ListsMembersCreate < CustomListMember
    END_POINT = '/1.1/lists/members/create.json'

    public

    def perform()
      hash = @requester.post(END_POINT, @options)
      result = Tw::ListAddRemoveResult.new(hash, @followers)
      return result
    end
  end

  #------------------------------------------------------------------
  # リストからメンバーを外す（1人だけバージョン）
  # https://dev.twitter.com/rest/reference/post/lists/members/destroy
  #------------------------------------------------------------------
  class ListsMembersDestroy < CustomListMember
    END_POINT = '/1.1/lists/members/destroy.json'

    public

    def perform()
      hash = @requester.post(END_POINT, @options)
      result = Tw::ListAddRemoveResult.new(hash, @followers)
      return result
    end
  end

end
