# encoding: UTF-8
# このファイルはＵＴＦ－８です。

$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

# Catched at user_info.rb:33:TypeError:can't convert Array to Hash (Array#to_hash gives Array):#<TypeError: can't convert Array to Hash (Array#to_hash gives Array)>:
# If you want backtrace, define an environment valuable TWBT.
# /var/lib/gems/1.9.1/gems/simple_oauth-0.3.1/lib/simple_oauth/header.rb:90:in `[]
# などとエラーが出るので、一時しのぎ。
#
# ここから、
#   cp -p /usr/lib/ruby/vendor_ruby/nokogiri/xml/node.rb lib/nokogiri/xml/node.rb
OriginalArray = Array.clone
#OriginalHash  = Hash.clone
# ここまで。

require 'tracer'

#require 'oauth'
#require 'twitter'
#require 'time'
#require 'user_stream'
require 'yaml'
#require 'time'
require 'cgi'
require 'json'

# 2019-08-10
# Rainbow はいずれ取り除く必要があると思う。
require 'rainbow/ext/string'
require 'rainbow'

#require 'set'
require "key/#{::CLIENT_NAME}-keys"
require 'utility/utility'
require 'conf'
require 'version'
require 'utility/force'
require 'utility/not_nil.rb'
require 'utility/error_helper.rb'
require 'utility/string_extension'
require 'utility/file_cacheable_array'
require 'utility/boolean'
require 'utility/locale_inspector'
require 'utility/shell_escape_sequence'
require 'client/client'
require 'client/stream'
