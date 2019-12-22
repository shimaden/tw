# encoding: UTF-8
module Tw
end

module Tw::App
  class Geo

    protected

    # :lat  緯度：北緯 + 90.0 ～ 南緯 - 90.0  小数点以下8桁まで指定可能
    # :long 経度：東経 +180.0 ～ 西経 -180.0  小数点以下8桁まで指定可能
    # 座標つき地図サイト https://maps.google.co.jp/
    #
    # New Orleans, Louisiana (LA)
    NewOrleans = [29.964722, -90.081389]
    NewOrleans_LouisArmstrongPark \
               = [29.963305, -90.069572]

    # Natchez, Mississippi (MS)
    Natchez    = [31.561533, -91.404535]

    # Greenville, Mississippi (MS)
    Greenville = [33.399417, -91.032182]

    # Nashville, Tennesee (TN 37201)
    #   ￥20,885▼Hotel Indigo Nashville
    #   301 Union Street
    #   Nashville, TN 37201, United States
    #   +1 615-891-6000
    Nashville  = [36.165904, -86.77874]

    #  Lexington, Kentucky (KY 40508)
    #  University of Kentucky
    #  209 Student Center | Lexington, KY | 40506-0030
    #  ph (859) 257-5781 fax (859) 323-1024
    Lexington = [38.040582, -84.503717]

    # 1151-1173 Madison Ave
    # Covington, KY 41011
    Covington = [39.078217, -84.508553]

    # Maryland Historical Society詳細?
    # 201 West Monument Street
    # Baltimore, MD 21201, United States
    # +1 410-685-3750
    Baltimore = [39.297298, -76.619056]

    Indiana   = [39.792485, -86.152034]

    # カラマズー・エリア・マス & サイエンス詳細
    # Kalamazoo Area Mathematics & Science Center
    # http://www.kamsconline.com/
    # 600 West Vine Street Suite 400, Kalamazoo, MI 49008
    # Kalamazoo, Michigan 49008, United States
    # Phone: (269) 337-0004; Fax: (269) 337-0049
    # +1 269-337-0004
    # Localtime: UTC/GMT -5 hours EST - Eastern Standard Time
    Kalamazoo = [42.284856, -85.590631]

    # BB's Jazz, Blues and Soups
    # 700 South Broadway , St. Louis, MO 63102 (Missouri)
    # (314) 436-5222
    StLouis   = [38.619746, -90.192103]

    # The University of Illinois at Chicago イリノイ大学
    # 1200 W Harrison St
    # Chicago, Illinois 60607
    Chicago   = [41.869132, -87.648622]

    # Francis Tuttle Technology Center
    # 12777 N. Rockwell Ave Oklahoma City,
    # OK 73142 ・ Phone 405.717.7799
    # :lat => 35.5962718, -97.6387332
    #
    Oklahoma  = [35.5962718, -97.6387332]

    # Midwestern Baptist Theological Seminary
    # 5001 North Oak Trafficway
    # Kansas City, Missouri 64118
    #
    # 800-944-MBTS (6287)
    # 816-414-3700
    KansasCity = [39.188912,  -94.576964]

    # アラスカ大学フェアバンクス校
    # The University of Alaska Fairbanks
    # 400 Front St, Nome, AK 99762
    # +1 907-443-2201
    # uaf.web@alaska.edu
    AlaskaUniv = [64.4975467, -165.3980449]

    # The University of Edinburgh
    # Old College
    # South Bridge
    # Edinburgh EH8 9YL, UK
    # +44 131 650 1000
    Edinburgh  = [55.9458193, -3.1890065]

    # University of Cambridge
    # The Old Schools
    # Trinity Ln
    # Cambridge CB2 1TN, UK
    Cambridge  = [52.2042867, 0.1155937]

    # Haven High Technology College
    # Haven High Academy Marian Road,
    # Boston, Lincs, PE21 9HB,
    # United Kingdom
    # Telephone: +44 (0)1205 311 979
    # Fax: +44 (0)1205 362850
    # Staff Absence (7.30am - 8.00am): 01205 319503
    BostonUK = [52.9888724, -0.0256495]

    # University Offices
    # Wellington Square
    # Oxford OX1 2JD, UK
    OxfordUniv = [51.7572628, -1.2532957]

    # 楽器博物館
    # Musical Instrument Museum
    # Hofberg 2 Montagne de la Cour
    # B-1000 Brussels (Belgium)
    # tel. +32 2 545 01 30
    # fax +32 2 545 01 77
    Brussels_Belgium = [50.8452074, 4.3589748]

    # ルートヴィヒ美術館
    # Heinrich-Böll-Platz
    # 50667 Kölnドイツ
    # +49 221 16875139
    Heinrich_Boell_Platz = [50.9412636, 6.9578636]

    # ウィーン楽友協会
    # Gesellschaft der Musikfreunde in Wien
    # Musikvereinsplatz 1
    # 1010 Wien
    # オーストリア
    # E-Mail: tickets@musikverein.at
    Wien = [48.202802, 16.3688817]

    # The National Museum of Bosnia and Herzegovina
    # Zmaja od Bosne 3
    # Sarajevo 71000
    # ボスニア・ヘルツェゴビナ
    Sarajevo = [43.8551256, 18.4024295]

    # McDonalds
    # Importanne prolaz
    # 10000, Zagreb
    # Republika Hrvatska
    # クロアチア Croatia
    Croatia = [45.8035733, 15.9776256]

    # サンカルロ歌劇場
    # Via San Carlo, 98
    # 80132 Napoli
    # イタリア
    Napoli = [40.8375397, 14.2496114]

    # Trullidea
    # Via Monte San Gabriele, 14
    # 70011 Alberobello Bari
    # Italy
    Alberobello = [40.782682, 17.237542]

    # Associação De Estudantes Da Faculdade De Ciências Médicas De Lisboa
    # Campo Mártires da Pátria 130
    # 1169-056 Lisboa
    # ポルトガル Portugal
    Portugal = [38.7174375, -9.1369575]

    # アレクサンドリア図書館
    # Chatby
    # Alexandria 21526
    # エジプト
    Egypt = [31.2005105, 29.9146742]

    # 京都大学
    # 日本
    # 〒606-8501 京都府京都市左京区吉田本町
    # +81 75-753-7531
    Kyoto = [35.0270655, 135.7809454]

    # 〒441-3421 愛知県田原市田原町東大浜
    # 一品料理めぐみ
    Tawara = [34.6682112, 137.2710445]

    # 東京女子医科大学 大東キャンパス
    # 〒437-1434 静岡県掛川市下土方４００−２
    # +81 537-63-2111
    Kakegawa = [34.7102073, 138.0479249]

    # 〒418-0077 静岡県富士宮市中央町１５−１８
    # 富士宮富士急ホテル
    Shizuoka = [35.2214246, 138.6159558]

    # 〒194-0013 東京都町田市原町田１丁目３
    # 早稲田塾町田校
    Machida = [35.540803, 139.4461934]

    # 〒196-0033 東京都昭島市東町１丁目５−１
    # ライオンズステージ西立川フォレストアヴェニュー
    Akishima = [35.702811, 139.3925304]

    # ロスアラモス国立研究所
    LosAlamos = [35.8440582, -106.287162]

    # 台北 故宮博物院
    TaipeiKokyu = [25.1023602, 121.5463038]

    CurrentLoc = LosAlamos

#----------------------------------------------------------

    CurrentLocation = {:lat => CurrentLoc[0], :long => CurrentLoc[1]}

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
    Granularity = City

    # Goole Map
    # https://www.google.co.jp/maps/@35.673343,139.710388,11z?hl=en
  end
end
