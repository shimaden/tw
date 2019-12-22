# encoding: UTF-8
# Adds some methods to the String class.
#
# 注意: Ruby での文字列リテラル '\\' は「\」を表す。
#       "\\" も「\」を表す。
#       「\」文字は、"" 内でも '' 内でもエスケープとして
#       働く（っぽい）。
#
module StringExtension

  LF_CODE       = "\n"
  BACKSLASH     = '\\' # This is one backslash.
  BACKSLASH_DBL = BACKSLASH * 2

  LF_ON_SCREEN  = '\n' # This \ is not escaped.

  protected

  def color_code(str)
    colors = Rainbow::Color::Named::NAMES.keys - [:default, :black, :white]
    n = str.each_byte.map{|c| c.to_i}.inject{|a, b| a + b}
    return colors[n%colors.size]
  end

  public

  def char_length()
    return self.split(//u).size
  end

  # Decodes text returned from Twitter.
  def decode_html()
    return self.gsub('&lt;', '<').gsub('&gt;', '>').gsub('&amp;', '&')
  end

  # Replace every "\\n" and "\\\\" in this object to "\n" and "\\\\",
  # respectively.
  #
  #   Actually displayed =  Ruby code         => Converted string
  #   (line feed)        = "\n"               => (no conversion)
  #   \n                 = '\n' "\\n"         => LF
  #   \\                 = '\\\\'             => \
  #   \\\\               = '\\\\\\\\'         => \\
  #   \\\\\\\\           = '\\\\\\\\\\\\\\\\' => \\\\
  #
  # This is useful to send a message to Twitter to tweet (update).

  # 文字列中の2文字 '\n' を制御コード LF に変換する。
  #def decode_line_feed__()
  #  return self.gsub(LF_ON_SCREEN, LF_CODE).gsub(BACKSLASH_DBL, BACKSLASH)
  #end

  # このようにループで回さないと、
  #
  #   us '\\notice' => [LF]notice
  #
  # などが期待通りに働かない。
  def decode_line_feed()
    s = self.gsub(/\\./) {|str|
      case str[1]
      when BACKSLASH then
        BACKSLASH
      when 'n' then
        LF_CODE
      when '"' then
        '"'
      when '!' then
        '!'
      else
        str
      end
    }
  end

  # 文字列中の制御コード LF を '\n' の2文字にエスケープする。
  def escape_line_feed()
    return self.gsub(LF_CODE, BACKSLASH + LF_ON_SCREEN)
  end

  def safe_str()
    result = ""
    self.each_char do |c|
      bin = c.unpack("Un*")[0]
      if 0xD800 <= bin && bin <= 0xDBFF then
        ch = ""
      elsif 0xDC00 <= bin && bin <= 0xDFFF then
        ch = "　"
      elsif bin == 0xF09F then
        ch = ""
      elsif 0x1F300 <= bin && bin <= 0x1F5FF then
        ch = "　"
      else
        ch = [bin].pack("U*")
      end
      result += ch
    end
    return result
  end

  # 画面に表示する時に、全角文字を2文字分として数える。
  def display_width()
    count     = 0
    asc_count = 0
    utf_count = 0
    utf_byte  = 0
    self.bytes do |b|
      if (b & 0b10000000) == 0 then
        asc_count += 1
      else
        utf_count += 1
      end
    end
    return asc_count + utf_count / 3 * 2
  end
end

class String
  include StringExtension
end
