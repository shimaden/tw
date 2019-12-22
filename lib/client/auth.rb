# encoding: UTF-8
module Tw

  #-----------------------------------------
  # Auth クラス
  #-----------------------------------------
  class Auth
    attr_reader :user, :rest_client
    OAUTH_URL = 'https://api.twitter.com/'

    class User
      attr_reader :id, :screen_name
      def initialize(id, screen_name)
        @id = id
        @screen_name = screen_name
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
      @user_info = self.get_or_register_user()
      id = @user_info['id']
      screen_name = self.find_screen_name(id)
      @user = User.new(id, screen_name)
      @rest_client = Twitter::REST::Client.new do |c|
        c.consumer_key        = Conf['consumer_key']
        c.consumer_secret     = Conf['consumer_secret']
        c.access_token        = @user_info['access_token']
        c.access_token_secret = @user_info['access_secret']
      end
      return @rest_client
    end

      #---------------------------------------------------------
    protected
      #---------------------------------------------------------

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
      $stderr.puts "To get PIN, access:\n    #{request_token.authorize_url}"
      #
      # 　Launcy はウェブブラウザを fork して起動する。
      # そのときに起動したブラウザに対するキー入力がなぜか標準入力の
      # バッファに残る。PIN 文字列を入力したとき、うさこったーは
      # 「ゴミ文字列＋PIN 文字列」を受け取ってしまい、認証エラーが
      # 発生する。
      #
      #begin
      #  Launchy.open(request_token.authorize_url)
      #rescue Launchy::CommandNotFoundError => e
      #  $stderr.puts "Web browser is not found. To be authenticated, "    \
      #              "access the URL above with your web browser in the " \
      #              "login state on Twitter."
      #end
      begin
        print 'input PIN Number: '
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
        puts "Added \"@#{@user.screen_name}\""
        return Conf['users'][@user.screen_name]
      rescue OAuth::Unauthorized => e
        $stderr.puts experr(__FILE__, __LINE__, e)
      end
    end

  end
end
