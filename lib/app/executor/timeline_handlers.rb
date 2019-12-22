# encoding: UTF-8
module Tw::App

  class Executor < AbstractExecutor

  protected

  #**************************************************************************
  #
  #                          Timeline Handlers
  #
  #**************************************************************************

    class JSONOutputFileError < IOError
    end

    #----------------------------------------------------------------
    # File existance checker.
    #----------------------------------------------------------------
    def specified_json_file_exist?()
      filename = @options.save_as_json()
      if filename.is_a?(String) then
        return File.exist?(filename)
      else
        return false
      end
    end

    #----------------------------------------------------------------
    # Read home timeline.
    #----------------------------------------------------------------
    def timeline_home(optname, optarg)
      ret = nil
      fs  = nil
      begin
        if self.specified_json_file_exist? then
          raise JSONOutputFileError.new(blderr(__FILE__, __LINE__,
              "File already exists: \"#{@options.save_as_json()}\""))
        end

        self.client.new_auth(@account)
        count           = @options.count()
        max_id          = @options.max_id()
        since_id        = @options.since_id()
        reply_depth     = @options.reply_depth()


        timeline = self.client.home_timeline(
                              count,
                              max_id,
                              since_id,
                              reply_depth)
        if !@options.save_as_json? then
          self.renderer.display(timeline, @options.format(), separator: "\n", current_user_id: self.client.current_user_id, no_retweets: @options.no_retweets?)
        else
          fs = FileSaver.create(@options.save_as_json(), "w", :json)
          fs.save(timeline)
        end
        ret = 0
      rescue JSONOutputFileError => e
        $stderr.puts(e.message)
        ret = 1
      ensure
        if fs.is_a?(FileSaver) then
          fs.close()
        end
      end
      return ret
    end

    #----------------------------------------------------------------
    # Read mentions timeline.
    #----------------------------------------------------------------
    def timeline_mentions(optname, optarg)
      ret = nil
      fs  = nil
      begin
        if self.specified_json_file_exist? then
          raise JSONOutputFileError.new(blderr(__FILE__, __LINE__,
              "file already exists: \"#{@options.save_as_json()}\""))
        end

        self.client.new_auth(@account)
        count           = @options.count()
        max_id          = @options.max_id()
        since_id        = @options.since_id()
        reply_depth     = @options.reply_depth()

        timeline = self.client.mentions_timeline(
                              count,
                              max_id,
                              since_id,
                              reply_depth)
        if !@options.save_as_json? then
          self.renderer.display(timeline, @options.format(), separator: "\n", current_user_id: self.client.current_user_id, no_retweets: @options.no_retweets?)
        else
          fs = FileSaver.create(@options.save_as_json(), "w", :json)
          fs.save(timeline)
        end
        ret = 0
      rescue JSONOutputFileError => e
        $stderr.puts(e.message)
        ret = 1
      ensure
        if fs.is_a?(FileSaver) then
          fs.close()
        end
      end
      return ret
    end

    #----------------------------------------------------------------
    # Read user timeline
    #----------------------------------------------------------------
    def timeline_user(optname, optarg)
      ret = nil
      fs  = nil
      begin
        if self.specified_json_file_exist? then
          raise JSONOutputFileError.new(blderr(__FILE__, __LINE__,
              "file already exists: \"#{@options.save_as_json()}\""))
        end

        self.client.new_auth(@account)
        user = self.user_name_or_id(optarg)
        if user.nil? then
          $stderr.puts("user must be a user-id/@screen_name")
          return 1
        end

        count           = @options.count()
        max_id          = @options.max_id()
        since_id        = @options.since_id()
        reply_depth     = @options.reply_depth()

        timeline = self.client.user_timeline(
                                user,
                                count,
                                max_id,
                                since_id,
                                reply_depth)
        if !@options.save_as_json? then
          self.renderer.display(timeline, @options.format(), separator: "\n", current_user_id: self.client.current_user_id, no_retweets: @options.no_retweets?)
        else
          fs = FileSaver.create(@options.save_as_json(), "w", :json)
          fs.save(timeline)
        end
        ret = 0
      rescue JSONOutputFileError => e
        $stderr.puts(e.message)
        ret = 1
      rescue Tw::Error
        raise
      rescue => e
        ret = self.show_rescue(__FILE__, __LINE__, __method__, e,
                               {:user => user})
        raise
      ensure
        if fs.is_a?(FileSaver) then
          fs.close()
        end
      end
      return ret
    end

    #----------------------------------------------------------------
    # Read retweets-of-me timeline
    #----------------------------------------------------------------
    def timeline_retweets_of_me(optname, optarg)
      ret = nil
      fs  = nil
      begin
        if self.specified_json_file_exist? then
          raise JSONOutputFileError.new(blderr(__FILE__, __LINE__,
              "file already exists: \"#{@options.save_as_json()}\""))
        end

        self.client.new_auth(@account)
        count           = @options.count()
        max_id          = @options.max_id()
        since_id        = @options.since_id()
        reply_depth     = @options.reply_depth()

        timeline = self.client.retweets_of_me_timeline(
                              count,
                              max_id,
                              since_id,
                              reply_depth)
        if !@options.save_as_json? then
          self.renderer.display(timeline, @options.format(), separator: "\n", current_user_id: self.client.current_user_id, no_retweets: @options.no_retweets?)
        else
          fs = FileSaver.create(@options.save_as_json(), "w", :json)
          fs.save(timeline)
        end
        ret = 0
      rescue JSONOutputFileError => e
        $stderr.puts(e.message)
        ret = 1
      ensure
        if fs.is_a?(FileSaver) then
          fs.close()
        end
      end
      return ret
    end

    #----------------------------------------------------------------
    # Read list timeline
    #----------------------------------------------------------------
    def timeline_list(optname, optarg)
      ret = nil
      fs  = nil
      begin
        if self.specified_json_file_exist? then
          raise JSONOutputFileError.new(blderr(__FILE__, __LINE__,
              "file already exists: \"#{@options.save_as_json()}\""))
        end

        self.client.new_auth(@account)
        if !@options.validate_screen_name_with_list_name?(optarg) then
          $stderr.puts("Invalid screen name and/or list name: #{optarg}")
          return 1
        end
        optarg =~ /^@([a-zA-Z0-9_]+)\/(.+)$/
        username = $1
        listname = $2

        count           = @options.count()
        max_id          = @options.max_id()
        since_id        = @options.since_id()
        reply_depth     = @options.reply_depth()

        timeline = self.client.list_timeline(
                                username,
                                listname,
                                count,
                                max_id,
                                since_id,
                                reply_depth)
        if !@options.save_as_json? then
          self.renderer.display(timeline, @options.format(), separator: "\n", current_user_id: self.client.current_user_id, no_retweets: @options.no_retweets?)
        else
          fs = FileSaver.create(@options.save_as_json(), "w", :json)
          fs.save(timeline)
        end
        ret = 0
      rescue JSONOutputFileError => e
        $stderr.puts(e.message)
        ret = 1
      rescue Tw::Error
        raise
      rescue => e
        ret = self.show_rescue(__FILE__, __LINE__, __method__, e,
                               {:user => username})
        raise
      ensure
        if fs.is_a?(FileSaver) then
          fs.close()
        end
      end
      return ret
    end

    #----------------------------------------------------------------
    # Read search timeline
    #----------------------------------------------------------------
    def timeline_search(optname, optarg)
      ret = nil
      fs  = nil
      begin
        if self.specified_json_file_exist? then
          raise JSONOutputFileError.new(blderr(__FILE__, __LINE__,
              "file already exists: \"#{@options.save_as_json()}\""))
        end

        self.client.new_auth(@account)
        query = {:q => optarg, :lang => nil, :locale => nil, :result_type => 'recent'}
        if query.empty? then
          $stderr.puts("query needed.")
          return 1
        end

        count           = @options.count()
        max_id          = @options.max_id()
        since_id        = @options.since_id()
        reply_depth     = @options.reply_depth()

        timeline = self.client.search_timeline(
                                query,
                                count,
                                max_id,
                                since_id,
                                reply_depth)
        if !@options.save_as_json? then
          self.renderer.display(timeline, @options.format(), separator: "\n", current_user_id: self.client.current_user_id, no_retweets: @options.no_retweets?)
        else
          fs = FileSaver.create(@options.save_as_json(), "w", :json)
          fs.save(timeline)
        end
        ret = 0
      rescue JSONOutputFileError => e
        $stderr.puts(e.message)
        ret = 1
      rescue Tw::Error
        raise
      rescue => e
        ret = self.show_rescue(__FILE__, __LINE__, __method__, e,
                               {:query => query})
        raise e
      ensure
        if fs.is_a?(FileSaver) then
          fs.close()
        end
      end
      return ret
    end

    #----------------------------------------------------------------
    # Read favorites timeline
    #----------------------------------------------------------------
    def timeline_favorites(optname, optarg)
      ret = nil
      fs  = nil
      begin
        if self.specified_json_file_exist? then
          raise JSONOutputFileError.new(blderr(__FILE__, __LINE__,
              "file already exists: \"#{@options.save_as_json()}\""))
        end

        self.client.new_auth(@account)
        user = self.user_name_or_id(optarg)
        if user.nil? then
          $stderr.puts("user must be a user-id/@screen_name")
          return 1
        end

        count           = @options.count()
        max_id          = @options.max_id()
        since_id        = @options.since_id()
        reply_depth     = @options.reply_depth()

        timeline = self.client.favorites_timeline(
                                user,
                                count,
                                max_id,
                                since_id,
                                reply_depth)
        if !@options.save_as_json? then
          self.renderer.display(timeline, @options.format(), separator: "\n", current_user_id: self.client.current_user_id, no_retweets: @options.no_retweets?)
        else
          fs = FileSaver.create(@options.save_as_json(), "w", :json)
          fs.save(timeline)
        end
        ret = 0
      rescue JSONOutputFileError => e
        $stderr.puts(e.message)
        ret = 1
      rescue Tw::Error
        raise
      rescue => e
        ret = self.show_rescue(__FILE__, __LINE__, __method__, e,
                               {:user => user})
        raise
      ensure
        if fs.is_a?(FileSaver) then
          fs.close()
        end
      end
      return ret
    end

  end

end
