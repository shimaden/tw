# encoding: UTF-8
# このファイルはＵＴＦ－８です。

module Tw

  #-----------------------------------------------
  # UserEntities クラス
  #-----------------------------------------------
  class UserEntities
    attr_reader :url, :description

    def initialize(entities = {})
      @url = nil
      @description = nil
      if entities.has_key?(:url)
        @url         = Tw::Url.new(entities[:url])
      end
      if entities.has_key?(:description)
        @description = entities[:description]
      end
    end

    # URL?
    def url?
      return !!@url
    end

    # URL
    def url
      return @url
    end

    # Descripton
    def description
      return @descripton
    end

    # to_json
    def to_json(*a)
      result = {}
      result[:url]         = @url if !!@url
      result[:description] = @description
      result.to_json(*a)
    end
  end

  #-----------------------------------------------
  # Url クラス
  #-----------------------------------------------
  class Url
    attr_reader :urls

    def initialize(url)
      @urls = url.nil? ? [] : Tw::Urls.new(url[:urls])
    end

    # URLs
    def urls
      return @urls
    end

    # to_json
    def to_json(*a)
      return {
        :urls => @urls
      }.to_json(*a)
    end
  end

  #-----------------------------------------------
  # Urls クラス
  #-----------------------------------------------

# [{:url=>"http://t.co/wFNaD5HLYK", :expanded_url=>"http://profile.ameba.jp/kenkoyoshida/", :display_url=>"profile.ameba.jp/kenkoyoshida/", :indices=>[0, 22]}]

  class Urls < ::Array

    def initialize(urls)
      urls.each do |u|
        self.push(UrlElement.new(u))
      end
    end

  end

  #-----------------------------------------------
  # UrlElement クラス
  #-----------------------------------------------
  class UrlElement
    attr_reader :url, :expanded_url, :display_url

    def initialize(url_elem)
      @url          = url_elem[:url]
      @expanded_url = url_elem[:expanded_url]
      @display_url  = url_elem[:display_url]
    end

    def url
      return @url
    end

    def expanded_url
      return @expanded_url
    end

    def display_url
      return @display_url
    end

    # to_json
    def to_json(*a)
      return {
        :url          => @url,
        :expanded_url => @expanded_url,
        :display_url  => @display_url
      }.to_json(*a)
    end
  end

end

# ------------------------------------
#   "entities": {
#     "url": {
#       "urls": [{
#         "url": "http:\/\/t.co\/78pYTvWfJd",
#         "expanded_url": "http:\/\/dev.twitter.com",
#         "display_url": "dev.twitter.com",
#         "indices": [0, 22]
#       }]
#     },
#     "description": {
#       "urls": []
#     }
#   }
#
# src = '"entities": {"url": {"urls": [{"url": "http:\/\/t.co\/78pYTvWfJd","expanded_url": "http:\/\/dev.twitter.com","display_url": "dev.twitter.com","indices": [0, 22]}]},"description": {"urls": []}}'ent = JSON.parse(src, {:symbolize_names => true})
#
# ------------------------------------
#
# p ent[:entities][:url][:urls][0][:display_url]
# "dev.twitter.com"
#
# p ent[:entities]
# {:url=>{:urls=>[{:url=>"http://t.co/78pYTvWfJd", :expanded_url=>"http://dev.twitter.com", :display_url=>"dev.twitter.com", :indices=>[0, 22]}]}}
#
# p ent[:entities][:url]
# {:urls=>[{:url=>"http://t.co/78pYTvWfJd", :expanded_url=>"http://dev.twitter.com", :display_url=>"dev.twitter.com", :indices=>[0, 22]}]}
#
# p ent[:entities][:url][:urls]
# [{:url=>"http://t.co/78pYTvWfJd", :expanded_url=>"http://dev.twitter.com", :display_url=>"dev.twitter.com", :indices=>[0, 22]}]
#
# p ent[:entities][:url][:urls][0]
# {:url=>"http://t.co/78pYTvWfJd", :expanded_url=>"http://dev.twitter.com", :display_url=>"dev.twitter.com", :indices=>[0, 22]}
#
# p ent[:entities][:url][:urls][0][:expanded_url]
# "http://dev.twitter.com"
#
# p ent[:entities][:url][:urls][0][:display_url]
# "dev.twitter.com"
#
# p ent[:entities][:url][:urls][0][:indices]
# [0, 22]
#
# p ent[:entities][:url][:urls][0][:indices][0]
# 0
#
# p ent[:entities][:url][:urls][0][:indices][1]
# 22
#
# ------------------------------------
