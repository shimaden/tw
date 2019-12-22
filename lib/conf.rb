# encoding: UTF-8
# Twitter My App でキーをリセット
# https://dev.twitter.com/apps

require 'fileutils'

module Tw
  class Conf
    include ::Utility

    CONF_FILE_DIR              = "#{ENV['HOME']}/.#{Tw::Conf::SOFTWARE_NAME}/"
    CONF_WEIGHTENED_TEXT_FNAME = "#{CONF_FILE_DIR}twitter_text.json"
    CONF_DIR_MODE              = 0700
    USER_DIR_MODE              = 0700
    FOLLOWERS_IDS_FNAME        = "followers_ids.txt"
    MUTES_IDS_FNAME            = "mutes_ids.txt"
    BLOCKS_IDS_FNAME           = "blocks_ids.txt"
    HELP_CONFIG_CACHE_FILE     = "user_data.json"
    LOG_FILE_NAME              = "#{Tw::Conf::SOFTWARE_NAME}.log"
    LOG_FILE_MODE              = 0600

    WEIGHTENED_TEXT_TEMPLATE   = File.expand_path('setting_files/twitter_text.json', File.dirname(__FILE__))

    # 初期設定
    def self.default
      Tw::Conf::read_key_file()
      return {
        'version'         => Tw::VERSION,
        'consumer_key'    => Tw::Conf.consumer_key,
        'consumer_secret' => Tw::Conf.consumer_secret,
        'default_user'    => nil,
        'users'           => {}
      }
    end

    def self.[](key)
      return ENV[key] || conf[key]
    end

    def self.[]=(key,value)
      return conf[key] = value
    end

    # 設定ファイルののディレクトリのパスを返す。
    def self.conf_file_dir
      return @@conf_file_dir ||= CONF_FILE_DIR
    end

    # 設定ファイルのパスを返す。
    def self.conf_file
      return @@conf_file ||= File.join(CONF_FILE_DIR, ".tw.yml")
    end

    # 280にしてから導入された weightened テキストのカウント方法を
    # 格納したファイル
    def self.weightened_text_file
      return CONF_WEIGHTENED_TEXT_FNAME
    end

    # 設定ファイルのパスを設定する。
    def self.conf_file=(fpath)
      return @@conf_file = fpath
    end

    # ユーザ・ディレクトリを返す。
    def self.user_directory(id)
      if !(id.to_s =~ /^[0-9]+$/) then
        raise ArgumentError.new("\'#{id}\' is not a valid user id.")
      end
      userdir = File.join(CONF_FILE_DIR, id.to_s)

      if !FileTest.exist?(userdir) then
        Dir.mkdir(userdir)
        File.chmod(USER_DIR_MODE, userdir)
      end
      return @@user_directory ||= userdir
    end

    # フォロワーの ID をキャッシュするファイル名
    def self.follower_ids_filename(id)
      return File.join(self.user_directory(id), FOLLOWERS_IDS_FNAME)
    end

    # Log file name.
    def self.log_file_name()
      return File.join(File.join(CONF_FILE_DIR, LOG_FILE_NAME))
    end

    # ファイル名
    def self.help_configure_filename(id)
      return File.join(self.user_directory(id), HELP_CONFIG_CACHE_FILE)
    end


    def self.conf
      @@conf ||= (
            res = default
            begin
              if !Dir.exists?(CONF_FILE_DIR) then
                Dir.mkdir(CONF_FILE_DIR, USER_DIR_MODE)
              end
              if File.exists?(self.conf_file) then
                # 設定ファイルが存在する。
                # ファイルを読み込む。
                data = nil
                self.open_conf_file do |f|
                  data = YAML::load(f.read)
                end
                # バージョン・チェック。
                if data['version'] < REQUIRE_VERSION then
                  puts "This is tw version #{Tw::VERSION}."
                  puts "Your config file is old ("
                     + data['version']+"). Reset tw settings?"
                  puts "[Y/n]"
                  res = data if $stdin.gets =~ /^n/i
                else
                  res = data
                end
              end
              if !File.exists?(self.weightened_text_file) then
              end
            rescue => e
              $stderr.puts(fmt_err_str(e))
              $stderr.puts("設定ファイルに不整合がないかどうか調べてみてください: #{conf_file}")
            end
            res
      )
    end

    # 読み込んだ設定ファイルをYAML 形式に変換。
    def self.to_yaml
      return self.conf.to_yaml
    end

    # 読み込んだ設定データを YAML 形式で設定ファイルに書き込む。
    def self.save()
      open_conf_file('w+') do |f|
        f.write conf.to_yaml
      end
    end

    # 設定ファイルの内容を更新する。
    def self.update_twitter_config(force_update=false)
      if self['twitter_config'].kind_of?(Hash)                              &&
         self['twitter_config']['last_updated_at']+60*60*24 > Time.now.to_i &&
         !force_update                                                    then
        return
      end
      self['twitter_config'] = {}
      self['twitter_config']['short_url_length'] = Tw::Client.client.configuration.short_url_length
      self['twitter_config']['short_url_length_https'] = Tw::Client.client.configuration.short_url_length_https
      self['twitter_config']['last_updated_at'] = Time.now.to_i
      self.save()
    end

    # ツイートに付加する位置情報を位置情報設定
    # ファイルから読み取る。
    def self.load_location_file()
      fname = CONF_FILE_DIR + "/location.txt"
      location = nil
      File.open(fname, "r") do |f|
        while s = f.gets() do
          puts(s)
        end
      end
    end


    private
    def self.open_conf_file(opt=nil, &block)
      if block_given? then
        yield open(self.conf_file, opt)
      else
        return open(self.conf_file, opt)
      end
      File.chmod(0600, self.conf_file) if File.exists?(self.conf_file)
    end
  end
end
