# encoding: UTF-8
require 'forwardable'

module Tw

  #==================================================================
  # UserMentions クラス
  #==================================================================
  class UserMentions
    extend ::Forwardable
    def_delegators :@array, :size, :[], :each, :select, :reject, :find,
                      :to_a, :collect, :map

    def initialize(user_mentions)
      @array = user_mentions.collect {|elem| Tw::UserMentionElem.new(elem)}
    end

    def to_a(*a)
      return @array.to_a(*a)
    end

    def to_json(*a)
      return @array.to_json(*a)
    end

  end

  #==================================================================
  # UserMentionsElem クラス
  #==================================================================
  class UserMentionElem
    attr_reader :id, :screen_name, :name, :indices

    def initialize(elem)
      if elem.nil? then
        return
      end
      #if elem.is_a?(Twitter::Entity::UserMention) then # Obsolete.
      #  raise TypeError.new("Obsolete type: #{elem.class}.")
      #  @id          = elem.id
      #  @screen_name = elem.screen_name
      #  @name        = elem.name
      #  @indices     = elem.indices
      #elsif elem.is_a?(Hash) then
      if elem.is_a?(Hash) then
        @id          = elem[:id]
        @screen_name = elem[:screen_name]
        @name        = elem[:name]
        @indices     = elem[:indices]
      else
        raise TypeError.new("elem must be a Hash but #{elem.class}.")
      end

    end

    def to_json(*a)
      {
        :id          => @id,
        :screen_name => @screen_name,
        :name        => @name,
        :indices     => @indices
      }.to_json(*a)
    end

  end

end


=begin

公式
  "entities":
  {
    "hashtags": [],
    "symbols": [],
    "urls": [],
    "user_mentions":
    [
      {
        "id": 6844292,
        "id_str": "6844292",
        "screen_name": "TwitterEng",
        "name": "Twitter Engineering",
        "indices": [81, 92]
      },
      {
        "screen_name": "TwitterOSS",
        "name": "Twitter Open Source",
        "id": 376825877,
        "id_str": "376825877",
        "indices": [121, 132]
      }
    ]
  }
=end
