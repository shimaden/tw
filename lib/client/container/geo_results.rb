# encoding: utf-8
require 'json'

module Tw

  class GeoResults
    attr_reader :attrs, :query, :result

    class Coordinates
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
    class Params
      attr_reader :atrrs, :accuracy, :coordinates, :granularity
      def initialize(hash)
        @attrs = hash
        @accuracy    = hash[:accuracy]
        @coordinates = Coordinates.new(hash[:coordinates]) if hash.has_key?(:coordinates)
        @granularity = hash[:granularity]
      end
      def to_json(*a)
        hash = @attrs.dup
        hash[:coordinates] = @coordinates if !!@coordinates
        return hash.to_json(*a)
      end
    end
    class Query
      attr_reader :atrrs, :params, :type, :url
      def initialize(hash)
        @attrs = hash
        @params = Params.new(hash[:params]) if hash.has_key?(:params)
        @type   = hash[:type]
        @url    = hash[:url]
      end
      def to_json(*a)
        hash = @attrs.dup
        hash[:params] = @params if hash.has_key?(:params)
        return hash.to_json(*a)
      end
    end

    class BoundingBox
      attr_reader :attrs, :coordinates, :type

      class Coordinate
        attr_reader :attrs, :coordinates
        def initialize(arr)
          @attrs = arr
          @coordinates = arr
        end
        def to_json(*a)
          return @attrs.to_json(*a)
        end
      end

      def initialize(hash)
        @attrs = hash
        @coordinates = hash[:coordinates].map{|e1| e1.map{|e2| Coordinate.new(e2)}}
        @type        = hash[:type]
      end
      def to_json(*a)
        hash = @attrs.dup
        hash[:coordinates] = @coordinates if hash.has_key?(:coordinates)
        return hash.to_json(*a)
      end
    end
    class ContainedWithin
      attr_reader :attrs
      def initialize(hash)
        @attrs = hash
        @attributes = hash[:attributes]
        @bounding_box = BoundingBox.new(hash[:bounding_box])
        @country      = hash[:country]
        @country_code = hash[:country_code]
        @full_name    = hash[:full_name]
        @id           = hash[:id]
        @name         = hash[:name]
        @place_type   = hash[:place_type]
        @url          = hash[:url]
      end
      def to_json(*a)
        hash = @attrs.dup
        hash[:bounding_box] = @bounding_box if hash.has_key?(:bounding_box)
        return hash.to_json(*a)
      end
    end
    class Place
      attr_reader :attrs, :attributes, :bounding_box, :contained_within,
                  :country ,:country_code, :full_name, :id, :name,
                  :place_type, :url
      def initialize(hash)
        @attrs = hash
        @attributes       = hash[:attributes] if !!hash[:attrubutes]
        @bounding_box     = BoundingBox.new(hash[:bounding_box]) if !!hash[:bounding_box]
        if !!hash[:contained_within] then
          @contained_within = hash[:contained_within].map{|elem| ContainedWithin.new(elem)}
        end
        @country          = hash[:country]
        @country_code     = hash[:country_code]
        @full_name        = hash[:full_name]
        @id               = hash[:id]
        @name             = hash[:name]
        @place_type       = hash[:place_type]
        @url              = hash[:url]
      end
      def to_json(*a)
        hash = @attrs.dup
        hash[:bounding_box]     = @bounding_box     if hash.has_key?(:bounding_box)
        hash[:contained_within] = @contained_within if hash.has_key?(:contained_within)
        return hash.to_json(*a)
      end
    end

    class Result
      attr_reader :attrs, :places
      def initialize(hash)
        @attrs = hash
        @places = hash[:places].map{|elem| Place.new(elem)} if hash.has_key?(:places)
      end
      def to_json(*a)
        hash = @attrs.dup
        hash[:places] = @places if hash.has_key?(:places)
        return hash.to_json(*a)
      end
    end

    def initialize(hash)
      @attrs = hash
      @query  = Query.new(hash[:query])
      @result = Result.new(hash[:result])
    end
    def to_json(*a)
      hash = @attrs.dup
      hash[:query]  = @query  if hash.has_key?(:query)
      hash[:result] = @result if hash.has_key?(:result)
      return hash.to_json(*a)
    end

  end

end
