#!/usr/bin/ruby
#
# Usage: ruby2.5 show_require.rb <target-ruby-program>
#
require 'rubygems'

module Kernel
  alias __require gem_original_require
  def gem_original_require(path)
    puts "#{path.ljust(30, " ")} from #{caller(1)[1]}"
    __require path
  end
  private :__require
  private :gem_original_require
end

load ARGV.shift
