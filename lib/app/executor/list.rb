# encoding: UTF-8
module Tw::App

  class Executor < AbstractExecutor
    protected

    #----------------------------------------------------------------
    # List owned by a specified user
    #----------------------------------------------------------------
    def lists_ownerships(optname, optarg)
      self.client.new_auth(@account)
      user = optarg

      #===== HARD CODING =====
      reply_depth = 0
      list = nil
      #=======================
      lists, exception = self.client.lists_ownerships(user, list)
      s = StringIO.new("", "r+")
      lists.each do |list|
        s.printf("List name: %s/%-10s\n", list.user.screen_name, list.name)
        s.printf("  ID         : %d\n", list.id)
        s.printf("  Mode       : %s\n", list.mode)
        s.printf("  Members    : %d\n", list.member_count)
        s.printf("  Subscribers: %d\n", list.subscriber_count)
        s.printf("  Slug       : %s\n", list.slug)
        s.printf("  Description: %s\n", list.description)
        s.printf("  URL        : %s\n", list.uri)
        s.printf("\n")
      end
      s.rewind()
      self.renderer.print(s.read)
      if exception then
        $stderr.puts("Error: #{exception.message}")
      end
      return 0
    end

    #----------------------------------------------------------------
    # List owned by a specified user
    #----------------------------------------------------------------
    def lists_memberships(optname, optarg)
      self.client.new_auth(@account)
      user = optarg

      #===== HARD CODING =====
      reply_depth = 0
      list = nil
      #=======================
      lists, exception = self.client.lists_memberships(user, list)
      s = StringIO.new("", "r+")
      lists.each do |list|
        s.printf("List: %s/%-10s\n", list.user.screen_name, list.name)
        s.printf("  ID         : %d\n", list.id)
        s.printf("  Mode       : %s\n", list.mode)
        s.printf("  Members    : %d\n", list.member_count)
        s.printf("  Subscribers: %d\n", list.subscriber_count)
        s.printf("  Slug       : %s\n", list.slug)
        s.printf("  Description: %s\n", list.description)
        s.printf("  URL        : %s\n", list.uri)
        s.printf("\n")
      end
      s.rewind()
      self.renderer.print(s.read)
      if exception then
        $stderr.puts("Error: #{exception.message}")
      end
      return 0
    end

    #----------------------------------------------------------------
    # Members of the specified list.
    #----------------------------------------------------------------
    def lists_members(optname, optarg)
      self.client.new_auth(@account)
      list = optarg

      list_id_reg = /^[0-9]+$/
      user_id_reg = /^([0-9]+):(.*)/
      screen_name_reg = /^@([^:]+):(.*)/
      url_reg = /^\/([^\/]+)\/.*\/([^\/]+)$/

      options = {}
      options[:count] = @options.count() if @options.count?
      if list =~ list_id_reg then
        options[:list_id] = Integer(list)
      elsif list =~ user_id_reg then
        matched = user_id_reg.match(list).to_a[1,2]
        options[:owner_id] = matched[0]
        options[:slug]     = matched[1]
      elsif list =~ screen_name_reg then
        matched = screen_name_reg.match(list).to_a[1,2]
        options[:owner_screen_name] = matched[0]
        options[:slug]              = matched[1]
      elsif list =~ url_reg then
        matched = url_reg.match(list).to_a[1,2]
        options[:owner_screen_name] = matched[0]
        options[:slug]              = matched[1]
      else
        raise CmdOptionError.new("Invalid command option(s).")
      end

      member_users, last_update_time = self.client.lists_members(options)

      if @options.format? then
        format = @options.format()
      else
        format = {:data_fmt => Tw::App::Renderer::FMT_SIMPLE}
      end
      opts = {:last_update_time => last_update_time}
      self.renderer.display(member_users, format, separator: "", current_user_id: self.client.current_user_id, options: opts)

      return 0
    end

    #-------------------------------------------------------
    # リストにメンバーを加える（1人だけバージョン）
    # list_id:(user_id|screen_name)
    # list_slug::(owner_id|owner_screen_name)
    # list_slug:(user_id|screen_name):(owner_id|owner_screen_name)
    #-------------------------------------------------------
    def lists_add_member(optname, optarg)
      self.client.new_auth(@account)
      list_param = optarg

      # list-id:user-id
      pattern_1 = /^([0-9]+):([0-9]+)$/
      # list-id:@user
      pattern_2 = /^([0-9]+):@([^:]+)$/
      # list-owner:slug:user-id
      pattern_3 = /^([0-9]+):([^:]+):([0-9]+)$/
      # list-owner:slug:@user
      pattern_4 = /^([0-9]+):([^:]+):@([^:]+)$/
      # @list-owner:slug:user-id
      pattern_5 = /^@([^:]+):([^:]+):([0-9]+)$/
      # @list-owner:slug:@user
      pattern_6 = /^@([^:]+):([^:]+):@([^:]+)$/

      if list_param =~ pattern_1 then
        matched = pattern_1.match(list_param).to_a[1..2]
        owner = nil
        list  = Integer(matched[0])
        user  = Integer(matched[1])
$stderr.puts("Owner: #{owner}, List ID: #{list}, User: #{user}")
      elsif list_param =~ pattern_2 then
        matched = pattern_2.match(list_param).to_a[1..2]
        owner = nil
        list  = Integer(matched[0])
        user  = matched[1]
$stderr.puts("Owner: #{owner}, List ID: #{list}, User: #{user}")
      elsif list_param =~ pattern_3 then
        matched = pattern_3.match(list_param).to_a[1..3]
        owner = Integer(matched[0])
        list  = matched[1]
        user  = Integer(matched[2])
$stderr.puts("Owner: #{owner}, List ID: #{list}, User: #{user}")
      elsif list_param =~ pattern_4 then
        matched = pattern_4.match(list_param).to_a[1..3]
        owner = Integer(matched[0])
        list  = matched[1]
        user  = matched[2]
$stderr.puts("Owner: #{owner}, List ID: #{list}, User: #{user}")
      elsif list_param =~ pattern_5 then
        matched = pattern_5.match(list_param).to_a[1..3]
        owner = matched[0]
        list  = matched[1]
        user  = Integer(matched[2])
$stderr.puts("Owner: #{owner}, List ID: #{list}, User: #{user}")
      elsif list_param =~ pattern_6 then
        matched = pattern_6.match(list_param).to_a[1..3]
        owner = matched[0]
        list  = matched[1]
        user  = matched[2]
$stderr.puts("Owner: #{owner}, List ID: #{list}, User: #{user}")
      else
$stderr.puts("Owner: #{owner}, List ID: #{list}, User: #{user}")
        raise CmdOptionError.new("Bad argument: list_id:user:owner")
      end

      if !self.prompt("Add member to list? (Y/N): ") then
        return EXIT_BY_NO
      end

      begin
        list = self.client.lists_members_create(list, user, owner)
        s = StringIO.new()
        s.printf("User is successfully added to list.\n")
        s.printf("  User @%s ==> list %s\n", list.user.screen_name, list.full_name)
        s.printf("  List ID    : %d\n", list.id)
        s.printf("  Full name  : %s\n", list.full_name)
        s.printf("  Mode       : %s\n", list.mode)
        s.printf("  Members    : %d\n", list.member_count)
        s.printf("  Subscribers: %d\n", list.subscriber_count)
        s.printf("  Slug       : %s\n", list.slug)
        s.printf("  Description: %s\n", list.description)
        s.printf("  URL        : %s\n", list.uri)
        s.printf("\n")
        s.rewind()
        self.renderer.print(s.read)
      rescue
        self.renderer.puts("User addition to list failed.")
        self.renderer.puts("Usage: #{CLIENT_NAME} --lists-add-member list-slug:user:owner")
        self.renderer.puts("Usage: #{CLIENT_NAME} --lists-add-member list-id:user")
        raise
      end

      return 0

    end
=begin
    def lists_add_member(optname, optarg)
      self.client.new_auth(@account)
      list_param = optarg

      list_id_specified_reg   = /^([0-9]+):([^:]+)(?::([^:]+))?$/
      list_slug_specified_reg = /^([^:]+):([^:]+)(?::([^:]+))?$/

      if list_param =~ list_id_specified_reg then
        matched = list_id_specified_reg.match(list_param).to_a[1..3]
        list  = matched[0]
        user  = matched[1]
        owner = matched[2]
$stderr.puts("List ID: #{list}, User: #{user}, Owner: #{owner}")
      elsif list_param =~ list_slug_specified_reg then
        matched = list_slug_specified_reg.match(list_param).to_a[1..3]
        list  = matched[0]
        user  = matched[1]
        owner = matched[2]
$stderr.puts("List slug: #{list}, User: #{user}, Owner: #{owner}")
      else
        raise CmdOptionError.new("Bad argument: list_id:user:owner")
      end

      if !self.prompt("Add member to list? (Y/N): ") then
        return EXIT_BY_NO
      end

      begin
        list = self.client.lists_members_create(list, user, owner)
        s = StringIO.new()
        s.printf("User is successfully added to list.\n")
        s.printf("  User @%s ==> list %s\n", list.user.screen_name, list.full_name)
        s.printf("  List ID    : %d\n", list.id)
        s.printf("  Full name  : %s\n", list.full_name)
        s.printf("  Mode       : %s\n", list.mode)
        s.printf("  Members    : %d\n", list.member_count)
        s.printf("  Subscribers: %d\n", list.subscriber_count)
        s.printf("  Slug       : %s\n", list.slug)
        s.printf("  Description: %s\n", list.description)
        s.printf("  URL        : %s\n", list.uri)
        s.printf("\n")
        s.rewind()
        self.renderer.print(s.read)
      rescue
        self.renderer.puts("User addition to list failed.")
        self.renderer.puts("Usage: #{CLIENT_NAME} --lists-add-member list-slug:user:owner")
        self.renderer.puts("Usage: #{CLIENT_NAME} --lists-add-member list-id:user")
        raise
      end

      return 0

    end
=end

    #-------------------------------------------------------
    # リストからメンバーを外す（1人だけバージョン）
    # list_id:(user_id|screen_name)
    # list_slug::(owner_id|owner_screen_name)
    # list_slug:(user_id|screen_name):(owner_id|owner_screen_name)
    #-------------------------------------------------------
    def lists_remove_member(optname, optarg)
      self.client.new_auth(@account)
      list_param = optarg

      list_id_specified_reg   = /^([0-9]+):([^:]+)(?::([^:]+))?$/
      list_slug_specified_reg = /^([^:]+):([^:]+)(?::([^:]+))?$/

      if list_param =~ list_id_specified_reg then
        matched = list_id_specified_reg.match(list_param).to_a[1..3]
        list  = matched[0]
        user  = matched[1]
        owner = matched[2]
$stderr.puts("List ID: #{list}, User: #{user}, Owner: #{owner}")
      elsif list_param =~ list_slug_specified_reg then
        matched = list_slug_specified_reg.match(list_param).to_a[1..3]
        list  = matched[0]
        user  = matched[1]
        owner = matched[2]
$stderr.puts("List slug: #{list}, User: #{user}, Owner: #{owner}")
      else
        raise CmdOptionError.new("Bad argument: list_id:user:owner")
      end

      if !self.prompt("Remove member from list? (Y/N): ") then
        return EXIT_BY_NO
      end

      begin
        list = self.client.lists_members_destroy(list, user, owner)
        s = StringIO.new()
        s.printf("User is successfully removed from list.\n")
        s.printf("  User @%s ==> list %s\n", list.user.screen_name, list.full_name)
        s.printf("  List ID    : %d\n", list.id)
        s.printf("  Full name  : %s\n", list.full_name)
        s.printf("  Mode       : %s\n", list.mode)
        s.printf("  Members    : %d\n", list.member_count)
        s.printf("  Subscribers: %d\n", list.subscriber_count)
        s.printf("  Slug       : %s\n", list.slug)
        s.printf("  Description: %s\n", list.description)
        s.printf("  URL        : %s\n", list.uri)
        s.printf("\n")
        s.rewind()
        self.renderer.print(s.read)
      rescue => e
        self.renderer.puts("User removal from list failed.")
        raise
      end

      return 0

    end

  end

end
