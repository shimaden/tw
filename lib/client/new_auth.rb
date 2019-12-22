# encoding: UTF-8
# このファイルはＵＴＦ－８です。
if __FILE__ == $0 then
require 'json'
require 'yaml'

#CLIENT_NAME = "us"

require File.expand_path('../key/us-keys', File.dirname(__FILE__))
require File.expand_path('../version', File.dirname(__FILE__))
require File.expand_path('../utility/utility', File.dirname(__FILE__))
require File.expand_path('../conf', File.dirname(__FILE__))

end

require 'oauth'
module Tw

  class NewAuth
    attr_reader :user
    OAUTH_URL = 'https://api.twitter.com/'

    class User
      attr_reader :id, :screen_name
      def initialize(id, screen_name)
        @id = id
        @screen_name = screen_name
      end
      def to_json(*a)
        return {
          :id => @id,
          :screen_name => @screen_name,
        }
      end
    end

    #---------------------------------------------------------
    # イニシャライザ
    #---------------------------------------------------------
    def initialize(user_info = nil)
      @user_info = user_info
    end

    #---------------------------------------------------------
    # ツイッター認証を受ける
    #---------------------------------------------------------
    def auth()
      @user_info    = self.get_or_register_user()
      @user_id      = @user_info['id']
      @screen_name  = self.find_screen_name(@user_id)
      @user         = User.new(@user_id, @screen_name)

      @consumer     = ::OAuth::Consumer.new(
                          Conf['consumer_key'],
                          Conf['consumer_secret'],
                          {:site   => OAUTH_URL, :scheme => :header}
                  )

      @access_token = ::OAuth::AccessToken.new(
                          @consumer,
                          @user_info['access_token'],
                          @user_info['access_secret']
                      )
    end

    protected

    #---------------------------------------------------------
    # ID からスクリーン・ネームを得る
    #---------------------------------------------------------
    def find_screen_name(id)
      screen_name = nil
      catch(:quit) do
        Conf['users'].each do |sname, attribs|
          attribs.each do |item, val|
            if item == 'id' then
              if val == id then
                screen_name = sname
                throw :quit
              end
            end
          end
        end
      end
      return screen_name
    end

      #---------------------------------------------------------
    public
      #---------------------------------------------------------

    #---------------------------------------------------------
    # Get user information from the configuration file, if exist.
    # If not exist, show the authentication URL of Twitter.
    #---------------------------------------------------------
    def get_or_register_user()
      if @user_info.nil? then
        if Conf['default_user'] then
          return Conf['users'][ Conf['default_user'] ]
        else
          return self.register_user()
        end
      end

      if @user_info.kind_of?(String) then
        if Conf['users'].include?(@user_info) then
          return Conf['users'][@user_info]
        else
          return self.register_user()
        end
      end

      if @user_info.kind_of?(Hash) then
        return @user_info
      end

      raise ArgumentError.new("#{bn(__FILE__)}:#{__LINE__}: " \
                "@user_info is expected nil, String or Hash, " \
                "but #{@user_info.class} is given.")

    end

    #---------------------------------------------------------
    # まだ設定ファイルになく、Twitter に認証もされていないユーザに、
    # Twitter 認証ページにアクセスさせ PIN を入力させ、Twitter に
    # 認証させる。
    #---------------------------------------------------------
    def register_user()
      consumer = OAuth::Consumer.new(
                                  Conf['consumer_key'],
                                  Conf['consumer_secret'],
                                  :site => OAUTH_URL)
      request_token = consumer.get_request_token()
      $stderr.puts("To get PIN, access:\n    #{request_token.authorize_url}")
      begin
        print('input PIN Number: ')
        verifier = $stdin.gets.strip
        # OAuth::AccessToken 型
        access_token = request_token.get_access_token(
                                            :oauth_verifier => verifier)
        @user = User.new(
                    Integer(access_token.params[:user_id]),
                    access_token.params[:screen_name])
        Conf['users'][@user.screen_name] = {
          'access_token'  => access_token.token,
          'access_secret' => access_token.secret,
          'id'            => @user.id
        }
        Conf['default_user'] = @user.screen_name unless Conf['default_user']
        Conf.save()
        puts("Added \"@#{@user.screen_name}\"")
        return Conf['users'][@user.screen_name]
      rescue OAuth::Unauthorized => e
        $stderr.puts(experr(__FILE__, __LINE__, e))
        raise
      end
    end

    def log_verify_result(file, line, endpoint, response)
      if @simple_log then
        msg = sprintf("%s(%d): INFO: Could't get user id and screen_name. " \
                      "Use config file data.", File.basename(file), line)
      else
        $stderr.puts("#{File.basename(file)}(#{line}): INFO: " \
                     "#{endpoint}: #{response.code()} #{response.message()}. " \
                     "Use #{@user_id} @#{@screen_name}")
      end
      $stderr.puts(msg)
    end

    def consumer()
      return @consumer
    end

    def access_token()
      return @access_token
    end

    def user_id()
      return @user_id
    end

    def screen_name()
      return @screen_name
    end

    def to_json(*a)
      return {
        :consumer     => @consumer, #.to_json(*a),
        :access_token => @access_token, #.to_json(*a),
        :user_id      => @user_id,
        :screen_name  => @screen_name,
        :user         => @user,
        :user_info    => @user_info,
      }
    end

  end

end
