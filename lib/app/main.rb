# encoding: UTF-8
# @SHIMADEN @KenkoYoshida @munyumomo 自分を遡るのは難しいww
# https://twitter.com/usakonigohan/status/424189359856680960
#
#require 'logger'
require File.expand_path('executor', File.dirname(__FILE__))
require File.expand_path('renderer', File.dirname(__FILE__))
require File.expand_path('geo', File.dirname(__FILE__))

module Tw
  BACKTRACE_MSG = "If you want backtrace, define an environment valuable TWBT."
end

module Tw::App

  def self.new()
    Main.new()
  end

  class Main
    attr_reader :logger
    include Utility

    #---------------------------------------------------------
    # Initializer.
    #---------------------------------------------------------
    def initialize()
      @sigint_handler = Proc.new() do
        $stderr.puts()
        $stderr.puts("いや～ん")
        $stderr.puts("SIGINT")
        exit 0
      end

    end

    #---------------------------------------------------------
    # Instance of Tw::Client
    #---------------------------------------------------------
    def client()
      @client ||= Tw::Client.new(
        followers_cache_options: {
          :permission => Executor::FOLLOWERS_CACHE_PERMISSON,
          :interval   => Executor::FOLLOWERS_CACHE_INTERVAL,
        },
        blocks_cache_options: {
          :permission => Executor::BLOCKS_CACHE_PERMISSON,
          :interval   => Executor::BLOCKS_CACHE_INTERVAL,
        },
        mutes_cache_options: {
          :permission => Executor::MUTES_CACHE_PERMISSON,
          :interval   => Executor::MUTES_CACHE_INTERVAL,
        }
      )
    end

    #---------------------------------------------------------
    # Instance of Tw::App::Renderer
    #---------------------------------------------------------
    def renderer()
      @renderer ||= Tw::App::Renderer.new()
    end

    #---------------------------------------------------------
    # 終了ステータス・メッセージ表示
    #---------------------------------------------------------
    def print_exit_msg(exit_code, exit_sub_code)
      msg = nil
      errstr = nil
      case exit_code
      when Executor::MULTI_CALL_ERR then
        msg = "Multi call error."
        errstr = exit_sub_code.join(" ")
      when Executor::TOO_FEW_ARGS_ERR then
        msg = "Too few arguments."
      when Executor::TOO_MANY_ARGS_ERR then
        msg = "Too many arguments."
      else
        msg = nil
      end
      return msg, errstr
    end

    #---------------------------------------------------------
    # メイン処理エントリ？？
    #---------------------------------------------------------
    def run(argv)
      exit_code = nil
      begin
        #@logger.debug("Enter: Tw::App::Main.run")

        Signal.trap(:INT, @sigint_handler)

        executor = Tw::App::AbstractExecutor.create(
                                self.renderer, self.client, self.logger)
        ret = executor.run()
        exit_code     = ret.code
        exit_sub_code = ret.sub_code

        #@logger.debug("Exit : Tw::App::Main.run(): status: #{exit_code}")

        msg, errstr = self.print_exit_msg(exit_code, exit_sub_code)

      rescue Tw::Error::Forbidden => e
        $stderr.puts("#{::CLIENT_NAME}: error: #{e.code} #{e.message}")
        exit_code = Executor::HTTP_FORBIDDEN
      rescue Tw::Error::NotFound => e
        $stderr.puts("#{::CLIENT_NAME}: error: #{e.code} #{e.message}")
        exit_code = Executor::HTTP_NOT_FOUND
      rescue Tw::Error::Unauthorized => e
        $stderr.puts("#{::CLIENT_NAME}: error: #{e.code} #{e.message}")
        exit_code = Executor::TW_UNAUTHORIZED
      rescue Tw::Error::ServiceUnavailable => e
        $stderr.puts("#{::CLIENT_NAME}: error: #{e.code} #{e.message}")
        exit_code = Executor::TW_SERVICE_UNAVAILABLE
      rescue Tw::Error::RequestTimeout => e
        $stderr.puts("#{::CLIENT_NAME}: error: #{e.code} #{e.message}")
        exit_code = Executor::HTTP_REQUEST_TIMEOUT
      rescue Tw::Error::InternalServerError => e
        $stderr.puts("#{::CLIENT_NAME}: error: #{e.code} #{e.message}")
        exit_code = Executor::HTTP_INTERNAL_SERVER_ERROR
      rescue Tw::Error::TooManyRequests => e
        $stderr.puts("#{::CLIENT_NAME}: error: #{e.code} #{e.message}")
        exit_code = Executor::HTTP_TOO_MANY_REQUESTS
      rescue Tw::Error::BadRequest => e
        $stderr.puts("#{::CLIENT_NAME}: error: #{e.code} #{e.message}")
        exit_code = Executor::HTTP_BAD_REQUEST

      rescue Executor::CmdOptionError => e
        $stderr.puts("#{::CLIENT_NAME}: error: #{e.message}")
        exit_code = Executor::INVALID_ARG_ERR
      rescue Net::OpenTimeout => e
        $stderr.puts("#{::CLIENT_NAME}: error: #{e.message}")
        exit_code = Executor::NETWORK_ERROR
      rescue Errno::EPIPE => e
        $stderr.puts("#{::CLIENT_NAME}: error: #{e.message}")
        exit_code = Executor::BROKEN_PIPE
      rescue Errno::ENOENT => e
        $stderr.puts("#{::CLIENT_NAME}: error: #{e.message}")
        exit_code = Executor::NO_SUCH_FILE_OR_DIR
      rescue Errno::ECONNRESET => e
        $stderr.puts("#{::CLIENT_NAME}: error: #{e.message}")
        exit_code = Executor::ECONNRESET
      raise SystemCallError => e
        exit_code = Executor::SYSTEM_CALL_ERROR
      rescue => e
        $stderr.puts("#{__FILE__}: #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}")
      end

      return exit_code
    end
  end
end
