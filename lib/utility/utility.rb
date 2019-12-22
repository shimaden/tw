# encoding: UTF-8

module Utility
  # 例外クラス e から、メッセージ文字列を作成する。
  def fmt_err_str(e)
    is_first = true
    s = nil
    e.backtrace.each do |bt|
      if is_first then
        s  = "#{bt}: #{e.message} (#{e.class})\n"
        is_first = false
      else
        s += "  #{bt}\n"
      end
    end
    return s
  end

  # UNIX パス名からベース名を取り出す。
  def bn(path)
    path.split(/\//).last
  end
end
