# encoding: UTF-8

# A urls is an array of objects.

module Tw

  class TweetEntitiesUrls

    def initialize(urls)
      @urlArr = []
      urls.each do |elem|
        @urlArr.push(Tw::TweetEntitiesUrlsElem.new(elem))
      end
    end

    def to_a(*a)
      return @urlArr.to_a(*a)
    end

    def to_json(*a)
      return @urlArr.to_json(*a)
    end

  end

  class TweetEntitiesUrlsElem
    attr_reader :indices, :url, :display_url, :expanded_url

    def initialize(elem)
      if elem.is_a?(Hash) then
        @attrs = elem
        @indices      = elem[:indices]
        @url          = elem[:url]
        @display_url  = elem[:display_url]
        @expanded_url = elem[:expanded_url]
      else
        raise TypeError.new("elem must be a Hash but #{elem.class}.")
      end
    end

    def to_json(*a)
      return @attrs.to_json(*a) if @attrs.is_a?(Hash)
      return {
        :indices      => @indices,
        :url          => @url,
        :display_url  => @display_url,
        :expanded_url => @expanded_url
      }.to_json(*a)
    end

  end

end

=begin

Tweet example
"urls":
[
  {
    "indices":[32,52],
    "url":"http:\/\/t.co\/IOwBrTZR",
    "display_url":"youtube.com\/watch?v=oHg5SJ\u2026",
    "expanded_url":"http:\/\/www.youtube.com\/watch?v=oHg5SJYRHA0"
  }
]


User example
"urls":
[
  {
    indices":[32,52],
     "url":"http:\/\/t.co\/IOwBrTZR",
    "display_url":"youtube.com\/watch?v=oHg5SJ\u2026",
    "expanded_url":"http:\/\/www.youtube.com\/watch?v=oHg5SJYRHA0"
  }
]




=end
