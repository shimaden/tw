# encoding: UTF-8
module Tw::App

  class Executor < AbstractExecutor
    #----------------------------------------------------------------
    # Ask Y/N
    #----------------------------------------------------------------
    def prompt(question)
      loop do

        begin
          $stdout.print(question)
          $stdout.flush()
#          if $stdin.gets.strip =~ /^[[:space:]]*Y/i then
          line = $stdin.gets
          if line.nil? then
            $stderr.puts("Standard input is nil for some reason.")
            return false
          end
          line.strip!
          if line =~ /^Y$/i then
            return true
          else
            puts "Not performed."
            return false
          end
        rescue ArgumentError => e
          $stderr.puts(e.message)
          next
        else
          raise
        end

      end

    end

  end

end
