# encoding: UTF-8
# 公式の説明
#   Entities クラス http://rdoc.info/gems/twitter/Twitter/Entities#entities%3F-instance_method
#                   https://dev.twitter.com/docs/entities

require File.expand_path('media', File.dirname(__FILE__))

module Tw

  #----------------------------------------------------------------------
  # Abstract Extended Entities class
  #----------------------------------------------------------------------
  class AbstractExtendedEntities
    private_class_method :new
    attr_reader :media

    def initialize()
        @media = nil
    end

    def media?()
      @media.not_nil?
    end

    def to_json(*a)
      return {
        :media => @media
      }.to_json(*a)
    end

  end

  #----------------------------------------------------------------------
  # Extended Entities class
  #----------------------------------------------------------------------
  class ExtendedEntities < AbstractExtendedEntities
    private_class_method :new

    def initialize()
      super()
    end

    def self.compose(tweet)
      if tweet.is_a?(Hash) || tweet.is_a?(Tw::DirectMessage) then
        return Tw::ExtendedEntitiesFromHash.new(tweet)
      else
        raise TypeError.new("tweet must be a Hash or a Tw::DirectMesaage but #{tweet.class}.")
      end
    end
  end

  #----------------------------------------------------------------------
  # EntitiesFromGem class
  #----------------------------------------------------------------------
  class ExtendedEntitiesFromGem < ExtendedEntities
    public_class_method :new

    def initialize(tweet)
      super()
      if tweet.attrs[:extended_entities] then
        extended_entities = tweet.attrs[:extended_entities]
        @media = Tw::ExtendedMedia.new(extended_entities[:media])
      end
    end
  end

  #----------------------------------------------------------------------
  # EntitiesFromHash class
  #----------------------------------------------------------------------
  class ExtendedEntitiesFromHash < ExtendedEntities
    public_class_method :new

    def initialize(tweet)
      super()
      if tweet[:extended_entities] then
        @media = Tw::ExtendedMedia.new(tweet[:extended_entities][:media])
      end
    end
  end

end
