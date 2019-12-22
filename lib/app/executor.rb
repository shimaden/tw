# encoding: UTF-8
require 'getoptlong.rb'
require File.expand_path('abstract_executor', File.dirname(__FILE__))
require File.expand_path('geo', File.dirname(__FILE__))
require File.expand_path('file_saver', File.dirname(__FILE__))
require File.expand_path('executor_exit_code', File.dirname(__FILE__))
require File.expand_path('executor/functions', File.dirname(__FILE__))
require File.expand_path('reply_formatter', File.dirname(__FILE__))
require File.expand_path('mention_formatter', File.dirname(__FILE__))

module Tw::App
  #**************************************************************************
  #    Executor class.
  #**************************************************************************
  class Executor < AbstractExecutor
    private_class_method :new

    #----------------------------------------------------------------
    # Initializer
    #----------------------------------------------------------------
    def initialize(logger)
      super()
      @options = Options.new()
    end

  #**************************************************************************
  #
  #                         Function Invoking
  #
  #**************************************************************************

    #----------------------------------------------------------------
    # Main method
    #----------------------------------------------------------------
    def run()
      ret = RetCode.new()
      begin
        # Push command line options into the @options Array.
        @parser.each do |optname, optarg|
          @options.append_option(optname, optarg)
        end

        # Login as a specified account.
        if @options.has_key?('--account') then
          self.account = @options['--account'].last
        end

        # The first argument is used for a tweet or a direct message.
        # More than one argument is given, exit with an error status code.
        #
        # コマンドラインの引数とオプションの数とで処理を分岐
        if ARGV.size == 1 then  # 引数が1個
          if @options.has_key?('--direct-message-to') then
            to_user = @options['--direct_message_to']
            message = ENV.key?("OCRA_EXECUTABLE") ? ARGV[0].encode(Encoding::UTF_8) : ARGV[0]
            self.direct_message_to('--direct-message-to', @options['--direct-message-to'][0])
          else
            if @options.has_key?('--tweet') then
              raise CmdOptionError.new("--tweet option can't be specified when the tweet message is given as an argument.")
            end
            message = ENV.key?("OCRA_EXECUTABLE") ? ARGV[0].encode(Encoding::UTF_8) : ARGV[0]
            ret = self.tweet(nil, message)
          end
          return ret
        elsif ARGV.size == 0 then # 引数なし
          if @options.empty? then
            ret.code = TOO_FEW_ARGS_ERR
            return ret
          end
        elsif ARGV.size >= 2 then # 引数大杉
          ret.code = TOO_MANY_ARGS_ERR
          return ret
        end

        # Perform the functions designated by options one by one.
        # 与えられたコマンドライン引数とオプションに従い、1つ1つ実際に仕事をする。
        @options.each do |optname, optargs|
          if optname.is_a?(StringWithFunction) then
            result = []
            optargs.each do |arg|
              result << optname.func.call(optname, arg)
            end
            if result.size == 1 then
              if result[0].is_a?(RetCode)
                ret = result[0]
              else
                ret.code = result[0]
              end
            elsif result.size >= 2 then
              if result.find{|v1, v2| v1 != 0} then
                ret.code = MULTI_CALL_ERR
                ret.add_sub_code(result)
              end
            end
          end
        end

      rescue GetoptLong::Error => e
        ret.code = 1
      rescue Tw::Error::Unauthorized,
             Tw::Error::RequestTimeout,
             Tw::Error::Forbidden,
             Tw::Error::NotFound,
             Tw::Error::InternalServerError,
             Tw::Error::ServiceUnavailable,
             Tw::Error::TooManyRequests,
             Tw::Error::BadRequest,
             Tw::App::Renderer::RenderingFormatError
        raise
      rescue ::TypeError
        raise
      rescue Net::OpenTimeout
        raise
      #rescue Errno::EPIPE, Errno::ENOENT
      rescue SystemCallError
        raise
      rescue CmdOptionError
        raise
      rescue Tw::Error  => e
        $stderr.puts(experr(__FILE__, __LINE__, e))
        ret.code = 1
      rescue => e
        $stderr.puts(experr(__FILE__, __LINE__, e))
        $stderr.puts(Tw::BACKTRACE_MSG)
        $stderr.puts(e.backtrace.join("\n")) if ENV["TWBT"]
        ret.code = 1
      end
      return ret
    end

      #--------------------------------------------------------------
    protected
      #--------------------------------------------------------------

  #**************************************************************************
  #
  #                     Accunt Manipulation Handlers
  #
  #**************************************************************************

    #----------------------------------------------------------------
    # Select account to login Twitter.
    #----------------------------------------------------------------
    def account=(val)
      @account = val
      #self.renderer.puts("Log in as @#{@account}")
      $stderr.puts("Log in as @#{@account}")
      return 0
    end

    #----------------------------------------------------------------
    # Add a new account.
    #----------------------------------------------------------------
    def account_add(optname, optarg)
      new_auth = self.client.new_auth(optarg)
      return 0
    end

    #----------------------------------------------------------------
    # List account.
    #----------------------------------------------------------------
    def account_list(optname, optarg)
      Tw::Conf['users'].keys.each do |name|
        self.renderer.puts(
              (name == Tw::Conf['default_user']) ? "* #{name}" : "  #{name}")
      end
      self.renderer.puts("(#{Tw::Conf['users'].size} users)")
      return 0
    end

    #----------------------------------------------------------------
    # Set the default account.
    #----------------------------------------------------------------
    def account_set_default(optname, optarg)
      Tw::Conf['default_user'] = optarg
      Tw::Conf.save()
      self.renderer.puts("set default user \"@#{Tw::Conf['default_user']}\"")
      return 0
    end

  #**************************************************************************
  #
  #                      Help and Version Handlers
  #
  #**************************************************************************

    #----------------------------------------------------------------
    # Show help.
    #----------------------------------------------------------------
    def help(optname, optarg)
      help_file_name = File.expand_path('help.txt', File.dirname(__FILE__))
      prg = Tw::Conf::SOFTWARE_NAME
      File.open(help_file_name, "r") do |f|
        while line = f.gets do
          self.renderer.puts(
                line.gsub(/%prg/, prg) \
                    .gsub(/%capitalized-prg/, prg.capitalize) \
                    .gsub(/%version/, Tw::VERSION))
        end
      end
      return 1
    end

    #----------------------------------------------------------------
    # Show version.
    #----------------------------------------------------------------
    def version(optname, optarg)
      ret = nil
      puts "optname: '#{optname}'"
      puts "optarg : '#{optarg}'"
      ret = 0
      return ret
    end

  #**************************************************************************
  #
  #                      Miscellaneous Methods
  #
  #**************************************************************************

    #----------------------------------------------------------------
    # line
    #----------------------------------------------------------------
    def line_str(n)
      line = ""
      n.times do line += "-" end
      return line
    end

  #**************************************************************************
  #
  #                        Default Value Getters
  #
  #**************************************************************************

    #----------------------------------------------------------------
    # Tw::CacheableFollowersIds.new の followers_cache_option を返す。
    #----------------------------------------------------------------
    def followers_cache_option()
      return {
        :filename   => Tw::Conf.follower_ids_filename(
                            self.client.new_auth.user_id),
        :permission => FOLLOWERS_CACHE_PERMISSON,
        :interval   => FOLLOWERS_CACHE_INTERVAL
      }
    end

    public

    #----------------------------------------------------------------
    # Tw::Configuration.new の help_conf_opts を返す。
    #----------------------------------------------------------------
    def help_configuration_options()
      return {
        :filename    => Tw::Conf.help_configure_filename(
                          self.client.new_auth.user_id),
        :permission => HELP_CONFIGURATION_CACHE_MODE,
        :interval   => HELP_CONFIGURATION_CACHE_INTERVAL
      }
    end

  end
end
