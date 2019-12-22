# encoding: UTF-8
# Twitter My App でキーをリセット
# https://dev.twitter.com/apps

module Tw
  class Conf
    KEY_FILE        = "#{ENV['HOME']}/.us-key"
    SOFTWARE_NAME   = ::CLIENT_NAME
    REQUIRE_VERSION = '1.0.0'

    @@consumer_key = nil
    @@consumer_secret = nil

    def self.read_key_file()
      File.open(KEY_FILE, "r") do |f|
        while line = f.gets() do
          line.strip!
          if line =~ /^Consumer Key:/i then
            @@consumer_key = line[/([a-zA-Z0-9]+)$/]
          elsif line =~/^Consumer Secret:/i then
            @@consumer_secret = line[/([a-zA-Z0-9]+)$/]
          end
        end
      end
    end

    def self.consumer_key()
      return @@consumer_key
    end

    def self.consumer_secret()
      return @@consumer_secret
    end
  end
end
