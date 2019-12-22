# encoding@ UTF-8
#
# A member of Tw::Tweet.
#
# Official document:
#   https://dev.twitter.com/docs/platform-objects/tweets
#

module Tw

  class CurrentUserRetweet
    attr_reader :id
    private_class_method :new

    def initialize(param)
      @id = param[:id]
    end

    public

    def self.compose(param)
      if param.nil? then
        return nil
      end
      if param.has_key?(:id) then
        return new(param)
      end
      return nil
    end

    def id()
      return @id
    end

    def to_json(*a)
      return {:id => @id}.to_json(*a)
    end

  end

end
