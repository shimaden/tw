# encoding: UTF-8
#require File.expand_path 'geo.data.rb', File.dirname(__FILE__)
require File.expand_path 'geo_data_loader.rb', File.dirname(__FILE__)

module Tw::App

  class Geo

    # Tw::Client クラスが来る。
    def initialize(tw_client)
      @tw_client = tw_client
    end

    protected

    # 位置情報を返す
    def current_coordinates()
      #return self.geo_coordinates()
      return CurrentLocation
    end

    # 粒度を返す
    def granularity()
      return Granularity
    end

    # geo_opts
    def geo_opts
      return {
        #:lat         => self.current_coordinates[:lat],
        #:long        => self.current_coordinates[:long],
        :lat         => self.current_coordinates[:lat],
        :long        => self.current_coordinates[:long],
        :accuracy    => 2,
#        :granularity => "city",
        :granularity => self.granularity(),
        :max_results => 1
      }
    end

    # こちらの指定した geo_opts を Twitter API に渡して、GEO code をもらう。
    # Tw::GeoResults 型が返される。
    def reverse_geocode()
      return @reverse_geocode ||= @tw_client.reverse_geocode(self.geo_opts)
    end

    public

    # Geocode を含んだ、ツイート送信用 options を返す
    #   lat  緯度
    #          北緯 + 90.0 ～ 南緯 - 90.0  小数点以下8桁まで指定可能
    #   long 経度
    #          東経 +180.0 ～ 西経 -180.0  小数点以下8桁まで指定可能
#    def current_geocode()
#      # Tw::GeoResults 型が返される
#      return self.reverse_geocode(self.geo_opts)
#    end

    # POST statuses/update 用のオプション
    def options_for_update()
      tweet_opts = {
        # :display_coordinates
        #   Whether or not to put a pin on the exact coordinates a tweet 
        #   has been sent from.
        #   PIN (short for "personal identification number").
        #   ツイートが送信された正確な座標を PIN に付加するかどうか。
        # 
        :display_coordinates => true,
        :place_id => self.reverse_geocode().attrs[:result][:places][0][:id]
      }
      tweet_opts.merge!(self.geo_opts())
      return tweet_opts
    end

    # "413ef5a0d23bfe4f"
    def id
      @location ||= self.reverse_geocode().attrs[:result][:places][0]
      @location[:id]
    end

    # "https://api.twitter.com/1.1/geo/id/413ef5a0d23bfe4f.json"
    def url
      @location ||= self.reverse_geocode().attrs[:result][:places][0]
      @location[:url]
    end

    # "city"
    def place_type
      @location ||= self.reverse_geocode().attrs[:result][:places][0]
      @location[:place_type]
    end

    # "Kalamazoo"
    def name
      @location ||= self.reverse_geocode().attrs[:result][:places][0]
      @location[:name]
    end

    "Kalamazoo, MI"
    def full_name
      @location ||= self.reverse_geocode().attrs[:result][:places][0]
      @location[:full_name]
    end

    "US"
    def country_code
      @location ||= self.reverse_geocode().attrs[:result][:places][0]
      @location[:country_code]
    end

    "United States"
    def country
      @location ||= self.reverse_geocode().attrs[:result][:places][0]
      @location[:country]
    end

    # style == :verbose
    #   場所タイプ: city
    #   国        : United States
    #   国コード  : US
    #   名称      : St. Louis
    #   正式名称  : St. Louis, MO
    #   URL       : https://api.twitter.com/1.1/geo/id/60e6df5778ff9dac.json

    # 位置情報を表す文字列。
    def location_string(style)
      if style == :verbose then
        "場所タイプ: #{self.place_type()}\n"   \
        "国        : #{self.country()}\n"      \
        "国コード  : #{self.country_code()}\n" \
        "名称      : #{self.name()}\n"         \
        "正式名称  : #{self.full_name()}\n"    \
        "URL       : #{self.url()}"
      elsif style == :simple then
        "場所：#{self.full_name()} 国：#{self.country()} " \
        "(#{self.place_type()})."
      end
    end

  end
end

# Example of self.current_geocode().attrs[:result][:places][0]
=begin
{
  :id=>"413ef5a0d23bfe4f",
  :url=>"https://api.twitter.com/1.1/geo/id/413ef5a0d23bfe4f.json",
  :place_type=>"city",
  :name=>"Kalamazoo",
  :full_name=>"Kalamazoo, MI",
  :country_code=>"US",
  :country=>"United States",
  :contained_within=>
  [
    {
      :id=>"67d92742f1ebf307",
      :url=>"https://api.twitter.com/1.1/geo/id/67d92742f1ebf307.json",
      :place_type=>"admin",
      :name=>"Michigan",
      :full_name=>"Michigan, US",
      :country_code=>"US",
      :country=>"United States",
      :bounding_box=>
      {
        :type=>"Polygon",
        :coordinates=>
        [
          [
            [-90.418392, 41.696118],
            [-82.12297099999999, 41.696118],
            [-82.12297099999999, 48.306062999999995],
            [-90.418392, 48.306062999999995]
          ]
        ]
      },
      :attributes=>{}
    }
  ],
  :bounding_box=>
  {
    :type=>"Polygon",
    :coordinates=>
    [
      [
        [-85.663515, 42.215564],
        [-85.53081, 42.215564],
        [-85.53081, 42.332752],
        [-85.663515, 42.332752]
      ]
    ]
  },
  :attributes=>{}
}
=end
