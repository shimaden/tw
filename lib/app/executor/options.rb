# encoding: UTF-8
# このファイルはＵＴＦ－８です。
#
# コマンド・ライン・オプションからデータを得るメソッド群。
#
require 'delegate'
#require File.expand_path('../../utility/utility', File.dirname(__FILE__))

module Tw::App

  #**************************************************************************
  #
  #                  Methods for Operation Modifiers
  #
  #**************************************************************************
  class Options < DelegateClass(::Hash)

    def initialize()
      super({})
    end

    protected

    public

    def append_option(optname, optarg)
      self[optname] = [] if !self.has_key?(optname)
      self[optname] << optarg
    end

    #----------------------------------------------------------------
    # Return a reply depth.
    #----------------------------------------------------------------
    def reply_depth()
      if self['--reply-depth'] then
        reply_depth = Integer(self['--reply-depth'].last)
      else
        reply_depth = Tw::App::Executor::DEFAULT_REPLY_DEPTH
      end
      return reply_depth
    end

    #----------------------------------------------------------------
    # Get format for display.
    #----------------------------------------------------------------
    def format()
      given_values = self['--format']
      array = given_values.nil? ? [] : given_values.last.split(",")
      expected_values = ['text', 'color', 'json', 'id', 'csv', 'array', 'simple', 'full']
      invalid_values = array - expected_values
      if invalid_values.size > 0 then
        raise AbstractExecutor::CmdOptionError.new("invalid value for --format: \"#{invalid_values.join(",")}\"")
      end

      format = {}

      if array.include?('text') then
        format[:data_fmt] = Tw::App::Renderer::FMT_TEXT
      elsif array.include?('color') then
        format[:data_fmt] = Tw::App::Renderer::FMT_COLOR
      elsif array.include?('json') then
        format[:data_fmt] = Tw::App::Renderer::FMT_JSON
      elsif array.include?('id') then
        format[:data_fmt] = Tw::App::Renderer::FMT_ID
      elsif array.include?('csv') then
        format[:data_fmt] = Tw::App::Renderer::FMT_CSV
      elsif array.include?('simple') then
        format[:data_fmt] = Tw::App::Renderer::FMT_SIMPLE # Users.
      elsif array.include?('full') then
        format[:data_fmt] = Tw::App::Renderer::FMT_FULL   # Users.
      else
        format[:data_fmt] = Tw::App::Renderer::FMT_COLOR  # Default value.
      end

      if array.include?('array') then
        format[:cmd_fmt] = Tw::App::Renderer::FMT_ARRAY
      else
        format[:cmd_fmt] = Tw::App::Renderer::FMT_NONE    # Default value.
      end

      if ENV['TERM'] == 'dumb' then
        if format[:data_fmt] == Tw::App::Renderer::FMT_COLOR then
          format[:data_fmt] = Tw::App::Renderer::FMT_TEXT
        end
      end

      return format
    end
    def format?()
      return self.has_key?('--format')
    end

    #----------------------------------------------------------------
    # Return true if 'yes' is assumed.
    #----------------------------------------------------------------
    def assume_yes?()
      return @force_assume_yes ? true : self.has_key?('--assume-yes')
    end
    def assume_yes=(val)
      @force_assume_yes = val
    end

    #----------------------------------------------------------------
    # Weather get a tweet or not before reply, retweet, favorite and so on.
    #----------------------------------------------------------------
    def get_tweet?()
      return !self.has_key?('--dont-get-tweet')
    end

    #----------------------------------------------------------------
    # Return an Array of file names of media files to attach to a tweet.
    #----------------------------------------------------------------
    def media_file_names()
      file_names = []
      file_names.push(self['--media1'].last) if !!self['--media1']
      file_names.push(self['--media2'].last) if !!self['--media2']
      file_names.push(self['--media3'].last) if !!self['--media3']
      file_names.push(self['--media4'].last) if !!self['--media4']
      return file_names
    end

    #----------------------------------------------------------------
    # Return a video file name to attach to a tweet.
    #----------------------------------------------------------------
    def video_file_name()
      fname = nil
      if self.has_key?('--video') then
        fname = self['--video'].last
      end
      return fname
    end

    #----------------------------------------------------------------
    # Additional user IDs and screen names for media and video upload.
    #----------------------------------------------------------------
    def additional_owners()
      if self.additional_owners? then
        result = self['--additional-owners'].last.split(',')
      else
        result = []
      end
      return result
    end
    def additional_owners?
      result = false
      if self.has_key?('--additional-owners') then
        value = self['--additional-owners'].last
        if self.validate_user_id_and_screen_name_csv(value) then
          result = true
        else
          raise AbstractExecutor::CmdOptionError.new("--additional-owners.")
        end
      end
      return result
    end

    #----------------------------------------------------------------
    # Return a URL of a quote tweet or DM deep link.
    #----------------------------------------------------------------
    def quote_tweet_url()
      url = nil
      if self.has_key?('--quote-tweet') then
        url = self['--quote-tweet'].last
      end
      return url
    end

    #----------------------------------------------------------------
    # Return media ids in CSV.
    #----------------------------------------------------------------
    def media_ids()
      ids_csv = nil
      if self.has_key?('--media-ids') then
        str = self['--media-ids'].last
        ids_csv = self.get_ids_in_csv(str)
      end
      return ids_csv
    end
    def media_ids?()
      return !!self.media_ids()
    end

    #----------------------------------------------------------------
    # Detect a CSV of tweet IDs.
    # Return:
    #   id_str: if id_str is in valid format of CSV of tweet ID(s).
    #   nil   : if is_str is in invalid format.
    #----------------------------------------------------------------
    def get_ids_in_csv(id_str)
      return (id_str =~ /^[0-9]+(,[0-9]+)*$/) ? id_str : nil
    end

    #----------------------------------------------------------------
    # Return an in-reply-to status id. For old style reply.
    #----------------------------------------------------------------
    def in_reply_to()
      ids = nil
      if self.has_key?('--in-reply-to') then
        ids = self.get_ids_in_csv(self['--in-reply-to'].last)
        if ids.nil? then
          raise AbstractExecutor::CmdOptionError.new("--in-reply-to invalid argument.")
        end
      end
      return ids
    end

    #----------------------------------------------------------------
    # Return an in-reply-to status id. For new auto populate style reply.
    #----------------------------------------------------------------
    def in_reply_to_new()
      ids = nil
      if self.has_key?('--in-reply-to-new') then
        ids = self.get_ids_in_csv(self['--in-reply-to-new'].last)
        if ids.nil? then
          raise AbstractExecutor::CmdOptionError.new("--in-reply-to invalid argument.")
        end
      end
      return ids
    end

    #----------------------------------------------------------------
    # Exclude specific user IDs when replying.
    #----------------------------------------------------------------
    def exclude_reply_user_ids()
      if self.exclude_reply_user_ids? then
        result = self['--exclude-reply-user-ids'].last.split(',')
      else
        result = []
      end
      return result
    end
    def exclude_reply_user_ids?
      result = false
      if self.has_key?('--exclude-reply-user-ids') then
        value = self['--exclude-reply-user-ids'].last
        if self.validate_user_id_and_screen_name_csv(value) then
          result = true
        else
          raise AbstractExecutor::CmdOptionError.new("--exclude-reply-user-ids.")
        end
      end
      return result
    end

    #----------------------------------------------------------------
    # Disable auto_populate_reply_metadata.
    #----------------------------------------------------------------
    def disable_auto_populate_reply_metadata?
      return self.has_key?('--disaboe-auto-populate-reply')
    end

    #----------------------------------------------------------------
    # Validate a screen name.
    #----------------------------------------------------------------
    def validate_screen_name?(str)
      return str =~ /^@[a-zA-Z0-9_]+$/
    end

    #----------------------------------------------------------------
    # Validate a screen name with list name.
    # A list's name must start with a letter and can consist only of 
    # 25 or fewer letters, numbers, "-", or "_" characters.
    #----------------------------------------------------------------
    def validate_screen_name_with_list_name?(str)
      return str =~ /^@[a-zA-Z0-9_]+\/.+$/
    end

    #----------------------------------------------------------------
    # Vlidete if the comma separated value contains only user IDs
    # and Screen names.
    #----------------------------------------------------------------
    def validate_user_id_and_screen_name_csv(str)
      return str =~ /^(:?@[a-zA-Z0-9_]+|[0-9]+)(:?,@[a-zA-Z0-9_]+|,[0-9]+)*$/
    end

    #----------------------------------------------------------------
    # Validate a comma separated value of IDs.
    #----------------------------------------------------------------
    def validate_id_csv?(str)
      return str =~ /^(:?[0-9]+)(:?,[0-9]+)*$/
    end

    #----------------------------------------------------------------
    # Return a value given with the '--count' option.
    #----------------------------------------------------------------
    def count()
      if self['--count'].is_a?(Array) then
        count = Integer(self['--count'].last)
      else
        count = AbstractExecutor::DEFAULT_TL_COUNT
      end
      return count
    end
    def count?
      return self.has_key?('--count')
    end

    #----------------------------------------------------------------
    # '--no-retweets'
    #----------------------------------------------------------------
    def no_retweets?
      return self.has_key?('--no-retweets')
    end

    #----------------------------------------------------------------
    # Return a value given with the '--max-id' option.
    #----------------------------------------------------------------
    def max_id()
      if self['--max-id'].is_a?(Array) then
        max_id = Integer(self['--max-id'].last)
      else
        max_id = nil
      end
      return max_id
    end

    #----------------------------------------------------------------
    # Return a value given with the '--since-id' option.
    #----------------------------------------------------------------
    def since_id()
      if self['--since-id'].is_a?(Array) then
        since_id = Integer(self['--since-id'].last)
      else
        since_id = nil
      end
      return since_id
    end

    #----------------------------------------------------------------
    # If a method fails, exit as success.
    #----------------------------------------------------------------
    def force?()
      return self.has_key?('--force')
    end

    #----------------------------------------------------------------
    # Get followed_by_info (so far) from cache.
    #----------------------------------------------------------------
    def from_cache?()
      return self.has_key?('--from-cache')
    end

    #----------------------------------------------------------------
    # File name to save to as JSON
    #----------------------------------------------------------------
    def save_as_json()
      if self['--save-as-json'].is_a?(Array) then
        filename = self['--save-as-json'].last
      else
        filename = nil
      end
      return filename
    end
    def save_as_json?
      return !!self.save_as_json()
    end

    #----------------------------------------------------------------
    # File name to save to as text.
    #----------------------------------------------------------------
    def save_as_text()
      if self['--save-as-text'].is_a?(Array) then
        filename = self['--save-as-text'].last
      else
        filename = nil
      end
      return filename
    end
    def save_as_text?
      return !!self.save_as_text()
    end

    #----------------------------------------------------------------
    # Return the save directory.
    #----------------------------------------------------------------
    def save_dir()
      result = nil
      begin
        if self['--save-directory'].is_a?(Array) then
          save_dir = self['--save-directory'].last
          if File::Stat.new(save_dir).directory? then
            result = save_dir
          end
        end
        return result
      rescue Errno::ENOENT => e  # ここは SystemCallError に置き換えない
        $stderr.puts(e.message)
        return nil
      end
      return result
    end

    #----------------------------------------------------------------
    # Retern message
    #----------------------------------------------------------------
    def message()
      if self['--message'].is_a?(Array) then
        message = self['--message'].last
      else
        message = ""
      end
      return message
    end

    #----------------------------------------------------------------
    # Whether command line only or not.
    #----------------------------------------------------------------
    def command_line_only?()
      return self.include?('--command-line-only')
    end

    #----------------------------------------------------------------
    # Cc: mode
    #----------------------------------------------------------------
    def cc?()
      return self.include?('--cc')
    end

    #----------------------------------------------------------------
    # Atach geometrical infomation to a tweet.
    #----------------------------------------------------------------
    def geo?
      return self.include?('--geo')
    end


    #----------------------------------------------------------------
    # Filter stream
    #----------------------------------------------------------------
    def filter_stream_follow()
      key = '--filter-stream-follow'
      result = nil
      if self.has_key?(key) then
        if self.validate_id_csv?(self[key].last) then
          result = self.get_ids_in_csv(self[key].last)
        end
      end
      return result
    end
    def filter_stream_follow?()
      key = '--filter-stream-follow'
      return self.has_key?(key) && self.validate_id_csv?(self[key].last)
    end

  end

end
