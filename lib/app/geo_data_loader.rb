# encoding: UTF-8
module Tw
end

module Tw::App
  class Geo

    protected

    # :lat  緯度：北緯 + 90.0 ～ 南緯 - 90.0  小数点以下8桁まで指定可能
    # :long 経度：東経 +180.0 ～ 西経 -180.0  小数点以下8桁まで指定可能
    # Google Map https://maps.google.co.jp/
    #

    Narita  = [35.771991, 140.3906614]
    KansaiAirport = [34.4320068, 135.2282052]
    ShiretokoMisaki = [44.2043, 145.1947]
    BangKok = [13.7244416, 100.3529194]
    KMITL   = [13.7297378, 100.7791675]
    TaipeiKokyu = [25.1023602, 121.5463038]
    TaiwanToen  = [24.9769226, 121.1391496]
    TaiwanDaxi  = [24.8851886, 121.2853226] # 大渓老街（桃園市）
    Berlin      = [52.5053992, 13.2351892 ]
    CurrentLocation = {:lat => TaiwanToen[0], :long => TaiwanToen[1]}

    def load_location()
    end

    def current_location()
      return CurrentLocation
    end

#----------------------------------------------------------

    def geo_coordinates()
      lat = self.geo_coodinates[0]
      long = self.geo_coordinates[1]
      return {:lat => self.current_location[0], :long => self.current_location[1]}
    end

    # Point Of Interest（poi）
    # 近所（neighborhood）
    # 都市（city）
    # 管理者（admin）
    # 国（country）のいずれか。
    POI     = "poi"
    Neigh   = "neighborhood"
    City    = "city"
    Admin   = "admin"
    Country = "country"
    #Granularity = Admin # choose one of them above.
    Granularity = City # choose one of them above.

    # Goole Map
    # https://www.google.co.jp/maps/@35.673343,139.710388,11z?hl=en
  end
end
