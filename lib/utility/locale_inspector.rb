# encoding: UTF-8
#
# See:
#   http://rubydoc.info/gems/locale/2.1.0/Locale#candidates-class_method
# (Top: https://rubygems.org/gems/locale )
#
require 'locale'

class LocaleInspector

  def self.can_use_Japanese?()
    # :type - The type of language tag:
    #     :common, :rfc, :cldr, :posix, :simple
    #
    # Simple - 言語・地域での表現。多くのプログラムはこの形式を使います。
    #     例: "ja-JP", "ja_JP"
    # Common - 言語・スクリプト・地域・付加情報、での表現です。
    #     例: "ja-Kana-JP-MOBILE", "ja_Kana_JP_MOBILE"
    # RFC   - IETF(RFC2646(BCP47))形式の表現です。
    # CLDR  - CLDR(Unicode Common Locale Data Repository)形式の
    #         表現（ロケールID）です。
    # POSIX - POSIX形式の表現です。(例) "ja_JP.UTF-8"
    types = [ :common, :rfc, :cldr, :posix, :simple ]
    langs = ["ja-JP", "ja"] # "ja-JP" で "ja_JP" もヒットする。
    can_use = false
    types.each do |type|
      locArr = Locale.candidates(
                    :type => type, :supported_language_tags => langs)
      can_use = locArr.grep(/^ja[^[:alnum:]]?/).size > 0
      break if can_use
    end

    return can_use
  end

end
