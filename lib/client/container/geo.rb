# encoding: utf-8
require 'json'

module Tw

  class Geo
    attr_reader :attrs, :coordinates, :type
    def initialize(hash)
      @attrs = hash
      @coordinates = hash[:coordinates]
      @type        = hash[:type]
    end
    def to_json(*a)
      return @attrs.to_json(*a)
    end
  end

end
