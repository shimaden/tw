# encoding: utf-8
require 'net/http'
require 'openssl'
require 'uri'
require 'nokogiri'

class TwitterScraper
  attr_reader :charset, :url, :twitter_site, :twitter_site_id,
              :twitter_title, :twitter_url, :uri_history
              :attrs

  USER_AGENT = 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:50.0) Gecko/20100101 Firefox/50.0'
  CA_PATH    = '/etc/ssl/certs'

  TWITTER_SITE    = 'twitter:site'
  TWITTER_SITE_ID = 'twitter:site:id'
  TWITTER_TITLE   = 'twitter:title'
  TWITTER_URL     = 'twitter:url'

  CURL = ['curl', '-s', '-i'].freeze

  def initialize()
    @uri_history = []
  end

  protected

  def view_headers(headers)
    headers.each do |key, value|
      $stderr.puts("#{key}: #{value}")
    end
  end

  def headers(host)
    header = {}
    header['Host']            = host
    header['User-Agent']      = USER_AGENT
    header['Referer']         = @uri_history.last if @uri_history.size > 0
    header['Accept']          = '*/*'
    #header['Accept-Language'] = 'ja,en-US;q=0.7,en;q=0.3'
    #header['Accept-Encoding'] = 'gzip, deflate, br'
    #header['Accept-Encoding'] = 'identity;q=1.0'
    #header['Connection']      = 'keep-alive'
    return header
  end

  def get_html_recursively(uri, limit)
    @uri_history << uri
    raise ArgumentError.new('HTTP redirect too deep') if limit == 0

    parsed_uri = URI.parse(uri)
    path = parsed_uri.path
    path += '?' + parsed_uri.query if parsed_uri.query != nil
    path = "/" if path == ""
    req = Net::HTTP::Get.new(path, self.headers(parsed_uri.host))
    http = Net::HTTP.new(parsed_uri.host, parsed_uri.port)
    if parsed_uri.port == 443 then
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.ca_path = CA_PATH
    end
    response = Net::HTTP.get_response(URI.parse(uri))
    case response
    when Net::HTTPRedirection # リダイレクトなら再帰的に呼び出す
      if response['location'] =~ /^https?:\/\// then
        next_uri = response['location']
      else
        parsed_uri.path = response['location']
        next_uri = parsed_uri.to_s
      end
      return self.get_html_recursively(next_uri, limit - 1)
    when Net::HTTPSuccess     # 成功
      return response
    when Net::HTTPFatalError
      return response
    else
      # レスポンスが 2xx(成功)でなかった場合に、
      # 対応する例外を発生させます。
      response.value
    end
    return response
  end

  def next_uri(header)
    found = false
    field = nil
    value = nil
    header.each do |line|
      field, value = line.match(/^([^:]+:)\s*(http.*)$/).to_a[1,2]
      if field =~ /location/i then
        break
      end
    end
    return value
  end

  def get_html(uri, limit)
    @uri_history.clear
    return self.get_html_recursively(uri, limit)
  end

  def get_value(key)
    if @attrs.has_key?(key) && @attrs[key].size > 0 then
      if key == TWITTER_SITE_ID then
        return @attrs[key] =~ /^[0-9]+$/ ? Integer(@attrs[key]) : nil
      else
        return @attrs[key]
      end
    else
      return nil
    end
  end

  def walk_node(node, depth)
    puts("node.children.size: #{node.size}")
    node.each do |node|
      puts("#{"  " * depth}NODE: #{node.name}")
      if node.children then
        walk_node(node.children, depth + 1)
      end
    end
  end

  public

  def parse(uri, limit = 20)
    begin
      response = self.get_html(uri, limit)
      charset = response.body.encoding.to_s
#$stderr.puts("uri: #{uri.inspect}")

      # HTML をパース
      doc = Nokogiri::HTML.parse(response.body, nil, charset)
#$stderr.puts("doc: #{doc.class}")
#exit

      # Twitter 関連のメタデータを得る
      twitter_meta_data = doc.xpath('//html/head/meta').select{|node|
        name = node.attribute('name')
        !!name && name.value =~ /^twitter/
      }.collect{|node|
        name = node.attribute('name')
        content = node.attribute('content')
        content_value = content.nil? ? "" : content.value
        [name.value, content_value]
      }.to_h
  
      @attrs = twitter_meta_data
      @twitter_site    = self.get_value(TWITTER_SITE)
      @twitter_site_id = self.get_value(TWITTER_SITE_ID)
      @twitter_title   = self.get_value(TWITTER_TITLE)
      @twitter_url     = self.get_value(TWITTER_URL)

      result = @attrs
    rescue RuntimeError, ArgumentError, SocketError => e
      $stderr.puts("#{__FILE__}:#{__LINE__}: #{e.message}")
      $stderr.puts(e.backtrace)
      result = nil
    rescue Net::HTTPFatalError => e
      $stderr.puts("#{__FILE__}:#{__LINE__}: #{e.message}")
      result = nil
    rescue ::TypeError => e
      $stderr.puts("#{__FILE__}:#{__LINE__}: #{e.message}")
      $stderr.puts("This error should be fixed.")
      result = nil
    end
      return result
  end

  def has_twitter_account?()
    return !!@twitter_site || !!@twitter_site_id
  end
 
end

if __FILE__ == $0 then
  url = (ARGV.size == 0) ? URL : ARGV[0]
  scraper = TwitterScraper.new()
  ret = scraper.parse(url)

  scraper.uri_history.each.with_index do |url, i|
    puts("Access[#{i + 1}]: #{url}")
  end

  if scraper.has_twitter_account? then
    puts()
    puts("twitter:site   : #{scraper.twitter_site}")
    puts("twitter:site:id: #{scraper.twitter_site_id}")
    puts("twitter:title  : #{scraper.twitter_title}")
    puts("twitter:url    : #{scraper.twitter_url}")
  else
    puts('No Twitter account found.')
  end
end
