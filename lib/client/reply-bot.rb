# encoding: UTF-8
require 'rubygems'
require 'net/https'
require 'twitter'
require 'json'
require 'pp'
require File.expand_path('../../../util/string', File.dirname(__FILE__))
require File.expand_path('../../custom-connection', File.dirname(__FILE__))
require File.expand_path('../../status/tweet', File.dirname(__FILE__))
require File.expand_path('../../status/message/message', File.dirname(__FILE__))

require File.expand_path('../../../util/profile-tool.rb', File.dirname(__FILE__))

module Smdn

  class ReplyBot < CustomConnection

    DEFAULT_USER_STREAM_VERSION = "2"
    HEADER = "RPLY BOT"

    PROF_PATH = File.expand_path(
                '../../../prof/' + File.basename(File.expand_path($0), ".rb"),
                File.dirname(__FILE__))

    def initialize(write_connection_log = false)
      super()

      Signal.trap(:SIGHUP,  Proc.new(){self.on_sighup()})
      Signal.trap(:SIGINT,  Proc.new(){self.on_sigint()})
      Signal.trap(:SIGTERM, Proc.new(){self.on_sigterm()})

      @in_dot = false
      @write_connection_log = write_connection_log
      @friends = nil

      userstream_version = "#{ENV["USAKO_BOT_USERSTREAM_VERSION"]}".strip
      if userstream_version == "" then
        userstream_version = DEFAULT_USER_STREAM_VERSION
        self.puts_msg("#{self.header}: Use Userstream version: " \
                      "#{userstream_version} (default).")
      elsif ["1.1", "2"].include?(userstream_version) then
        self.puts_msg("#{self.header}: Use Userstream version: " \
                      "#{userstream_version} (specified).")
      end
      @endpoint_version = userstream_version

      @mutex = Mutex.new()
      @mutex.synchronize do
        @exit_advised = false
        @exit_advisory_confirmed = false
      end
 
    end

    protected

    # 割り込みシグナル・ハンドラの中では、Mutex#synchronize は使えない。
    # 代わりに Thread.handle_interrup() を使う。
    # 割り込みがかかっていない状態でこれをやっても構わない。
    #
    def exit_advised=(val)
      Thread.handle_interrupt(RuntimeError => :never) do
        @exit_advised = val
      end
    end

if RUBY_VERSION[/^[0-9]+?/].to_i <= 1 then
    def exit_advised=(val)
      @mutex.synchronize do
        @exit_advised = val
      end
    end
end

    def exit_advised?()
      @mutex.synchronize do
        if @exit_advised && !@exit_advisory_confirmed then
          self.puts_msg("#{self.header}: Exit advisory confirmed.")
          @exit_advisory_confirmed = true
        end
        self.connection_log("#{self.header}: Exit advised: #{@exit_advised}, confirmed: #{@exit_advisory_confirmed}.")
        return @exit_advised
      end
    end

    def on_sighup()
    end

    def on_sigint()
      begin
        $stderr.puts()
        self.puts_msg("#{self.header}: SIGINT")
      ensure
        self.exit_advised = true
        if ProfileTool.instance.running? then
          ProfileTool.instance.stop()
          self.puts_msg("#{self.header}: Profiling stopped.")
        end
        self.puts_msg("#{self.header}: TERMINATED")
        exit(1)
      end
    end

    def on_sigterm()
      begin
        $stderr.puts()
        self.puts_msg("#{self.header}: SIGTERM")
      ensure
        self.exit_advised = true
        ProfileTool.instance.stop()
      end
    end

    def header()
      return HEADER
    end

    def connection_log(msg)
      self.puts_msg(msg) if @write_connection_log
    end

    def get_https(uri)
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      https.ca_file = HTTPS_CA_FILE_PATH
      https.verify_mode = OpenSSL::SSL::VERIFY_PEER
      https.verify_depth = 5
      return https
    end

    def get_request(uri, https)
      request = Net::HTTP::Get.new(uri.request_uri)
      request["User-Agent"] = self.user_agent
      request["Accept-Encoding"] = "identity;q=1.0"
      request.oauth!(https, self.consumer(), self.access_token())
      return request
    end

    def store_friends(status)
      if @friends.nil? && status[:friends] && status[:friends].is_a?(Array) then
        @friends = status[:friends].clone
      end
    end

    def json_format?(line)
      return !!(line =~ /^\{.*\}$/)
    end

    def friends?(status)
      return status[:friends] && status[:friends].is_a?(Array)
    end

    def get_status(line)
      if self.json_format?(line) then
        status = ::JSON.parse(line, :symbolize_names => true)
        @friends ||= status[:friends].clone if self.friends?(status)
      else
        status = nil
      end
      return status
    end

    def put_dot(line)
      if line.empty? then
        if @in_dot then
          $stderr.print(".")
        else
          self.puts_msg("#{self.header}: .", false)
          @in_dot = true
        end
      else
        if @in_dot then
          $stderr.puts()
          @in_dot = false
        end
      end
    end

    def connect()
      uri = URI.parse(self.doGetEndpoint())
      https = self.get_https(uri)  # => Net::HTTP class
      begin
        self.connection_log("#{self.header}: https: #{https.class}")
        https.start do |https|
          break if self.exit_advised?
          self.connection_log("#{self.header}: Connected.")
          request = self.get_request(uri, https)  # => Net::HTTP::Get class
          recv_buf = ""
 
          https.request(request) do |response|  # response: Net::HTTPResponse
            break if self.exit_advised?

            response.read_body do |chunk|  # chunk: String
              break if self.exit_advised?

              recv_buf << chunk  # recv_buf に受信テキスト・データをためていく

              # recv_buf から 1 行ずつ取り出して status に格納
              # （recv_buf は複数行格納している可能性もあるのでループで処理）
              while (line = recv_buf[/.+?(\r\n)+/m]) != nil do
                status = nil
                begin
                  recv_buf[0..line.size-1] = ""  # recv_buf の先頭の 1 行を消去
                  line.strip!
                  status = self.get_status(line)
                rescue => e
                  self.puts_msg("#{self.header}: In connection loop: " \
                                "#{e.class}: #{e.message}: \"#{line}\"")
                  break   # 例外を握りつぶし while を脱出。
                ensure
                  # status をこの #connect メソッドをを呼んでるブロックに渡す
                  # yield 中で発生した例外は yield に任せるので
                  # ここでは rescue しない。
                  yield(status) if status != nil
                  break if self.exit_advised?
                end
              end  # while
            end  # response.read_body
          end
        end
      ensure
        return if self.exit_advised?
        self.connection_log("#{self.header}: Disconnected. Try to reconnect.")
      end
    end

    def getEndpointVersion()
      return @endpoint_version
    end

    # エンドポイントを取得する。
    def doGetEndpoint()
    end

    # self.run() メソッドがツイートを受信したときに行う動作を実行する。
    def doOperation(status)
    end

    public

    # プロファイル付きの実行
    def run_profile()
      ProfileTool.instance.start(PROF_PATH) do
        self.run()
      end
    end

    # 動作させる。
    def run()
      begin
        self.puts_msg("#{self.header}: START")

        return if self.exit_advised?

        loop do
          break if self.exit_advised?
          begin
            self.connect do |status|
              status = Status.create(status, self.user_id, self.screen_name)
              self.doOperation(status)
            end
          # subclass of ::Zlib::Error
          rescue ::Zlib::BufError => e
            self.puts_msg("#{self.header}: !!!ZLIB ERROR!!! #{e.message}")
#            self.puts_msg("#{self.header}: #{e.message}")
            self.puts_msg("#{self.header}: Disconnected. Try to reconnect.")
            #raise StandardError.new("#{e.class}: #{e.message}")
            #raise
          rescue ::Net::HTTPBadResponse => e
            if self.exit_advised? then
              self.puts_msg("#{self.header}: #{e.class}: #{e.message}")
            else
              backtrace = true
              self.puts_errmsg(__FILE__, __LINE__, e, backtrace)
              self.puts_msg("#{self.header}: Disconnected. Try to reconnect.")
            end
          rescue ::Timeout::Error => e
            self.puts_msg("#{self.header}: #{e.message}")
            self.puts_msg("#{self.header}: Disconnected. Try to reconnect.")
          rescue ::OpenSSL::SSL::SSLError => e
            backtrace = false
            self.puts_errmsg(__FILE__, __LINE__, e, backtrace)
            self.puts_msg("#{self.header}: Disconnected. Try to reconnect.")
          rescue ::SystemCallError, ::IOError => e
            backtrace = true
            self.puts_errmsg(__FILE__, __LINE__, e, backtrace)
            self.puts_msg("#{self.header}: Disconnected. Try to reconnect.")
          rescue => e
            backtrace = true
            self.puts_errmsg(__FILE__, __LINE__, e, backtrace)
            self.puts_msg("#{self.header}: Disconnected. Try to reconnect.")
          ensure
            break if self.exit_advised?
            self.puts_msg("#{self.header}: Disconnected. Try to reconnect.")
          end
        end
      ensure
        if self.exit_advised? then
          self.puts_msg("#{self.header}: EXIT")
          return 0
        end
        self.puts_msg("#{self.header}: EXIT conection loop .")
      end
    end

  end

end
