# encoding: UTF-8
require 'cgi'

module Smdn
end

module Smdn::CGI

  # params is an array of [name, value]
  #
  def cgi_escape(params)
    if !(params.is_a?(Array) || params.is_a?(Hash)) then
      raise ::TypeError.new("params must be an Array of [name, value].")
    end
    return "" if params.size == 0

    if params.is_a?(Hash) then
      arr = []
      params.each{|name,value| arr.push([name.to_s, value])}
      params = arr
    end
    if params.empty? then
      raise ::ArgumentError.new("params is empty.")
    end

    result = ""
    is_first = true
    n = 0
    params.each do |pair|
      if !(pair.is_a?(Array) && pair.size == 2) then
        raise ::ArgumentError.new(
                          "params[#{n}] is not in [name, value] format.")
      end

      if is_first then
        result += "?#{pair[0]}=#{::CGI.escape(pair[1].to_s())}"
        is_first = false
      else
        result += "&#{pair[0]}=#{::CGI.escape(pair[1].to_s())}"
      end
      n += 1
    end
    return result
  end

end


if $0 == __FILE__ then
  include Smdn::CGI
  arr = [["param1", "value1"], ["param2", "aaa bbb@ddd"], ["param3", "日本語"]]
  puts(cgi_escape(arr))
end
