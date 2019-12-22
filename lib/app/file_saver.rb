# encoding: UTF-8

module Tw::App

  #******************************************************************
  # Abstract Class for File Saver classes.
  #******************************************************************
  class FileSaver
    private_class_method :new

    #***********************************
    # FileSaverError
    #***********************************
    class FileSaverError < ::IOError
      def initialize(message)
        super(message)
      end
    end

    #----------------------------------------------------------------
    # Create one of an object of Sub Class.
    #----------------------------------------------------------------
    def self.create(filename, mode, format)
      if filename.nil? then
        return NullFileSaver.new()
      end
      if File.exist?(filename) then
        raise FileSaverError.new(blderr(__FILE__, __LINE__,
              "file already exists: \"#{filename}\""))
      end

      case format
      when :json then
        fs = JSONFileSaver.new(filename, mode)
      else
        raise ::ArgumentError.new(blderr(__FILE__, __LINE__,
              "invalid format given: #{format}"))
      end

      return fs
    end

    def save(obj)
    end

    def close()
    end
  end


  #******************************************************************
  #              Class for Saving Tweets to File
  #******************************************************************
  class CustomFileSaver < FileSaver
    private_class_method :new

    #----------------------------------------------------------------
    # Save.
    #----------------------------------------------------------------
    def save(obj)
      if obj.is_a?(Array)
        obj.each do |elem|
          @io.puts(elem.to_json)
        end
      end
    end

    #----------------------------------------------------------------
    # Close the File.
    #----------------------------------------------------------------
    def close()
      if @io.not_nil? then
        @io.close()
      end
    end

  end

  #******************************************************************
  #                Class for Saving File in JSON
  #******************************************************************
  class JSONFileSaver < CustomFileSaver
    public_class_method :new

    #----------------------------------------------------------------
    # Initializer
    #----------------------------------------------------------------
    def initialize(filename, mode)
      @io = File.open(filename, mode)
    end

    #----------------------------------------------------------------
    # Save. (Concrete Method)
    #----------------------------------------------------------------
  end

  #******************************************************************
  # Null Object.
  #******************************************************************
  class NullFileSaver < FileSaver
    public_class_method :new
  end

end
