# encoding: UTF-8
#
# Escape sequence processor for shell commandlines.
#

module Sh
end

module Sh::Shell

  #===========================================================
  # Parent class
  #===========================================================
  class ShellEscapeSequence
    private_class_method :new
    ESC_CHAR = '\\'

    # Initializer.
    def initialize()
    end

    protected

    # Return the array of escapee charachters.
    def escapee()
    end

    public

    # Append an escape sequence character befor each escapee.
    def append_escape_characters(str)
      ostr = ""
      str.each_char do |c|
        if self.escapee().include?(c) then
          ostr += ESC_CHAR + c
        else
          ostr += c
        end
      end
      return ostr
    end

  end

  #===========================================================
  # For Bash
  #===========================================================
  class BashEscapeSequence < ShellEscapeSequence
    public_class_method :new
    ESCAPEE = ['"', '$', '`', '\\'].freeze()

    def initialize()
      super()
    end

    protected

    # Return the array of escapee charachters.
    def escapee()
      return ESCAPEE
    end
  end

  #===========================================================
  # For Zsh
  #===========================================================
  class ZshEscapeSequence < ShellEscapeSequence
    public_class_method :new

    ESCAPEE = ['!', '"', '$', '`', '\\'].freeze()
    EXTENDED_ESCAPEE = (ESCAPEE + ['^']).freeze() # when 'setopt extendedglob'

    def initialize(extendedglob)
      super()
      @extendedglob = extendedglob
    end

    protected

    # Return the array of escapee charachters.
    def escapee()
      if @extendedglob then
        return EXTENDED_ESCAPEE
      else
        return ESCAPEE
      end
    end
  end

end
