# encoding: UTF-8
# このファイルはＵＴＦ－８です。
module Tw; end
module Tw::App

  class Executor < AbstractExecutor

    protected

  #**************************************************************************
  #
  #                           API Limit Handler
  #
  #**************************************************************************

    #----------------------------------------------------------------
    # Show API limit.
    #----------------------------------------------------------------
    def api(optname, optarg)
      ret = nil
      info = ""
      apiname = optarg.frozen? ? optarg.dup : optarg
      limit = nil
      begin
        self.client.new_auth(@account)
        if optarg == "" then
          is_first = true
          resources = self.client.apilimit().rate_limit().resources
          resources.each do |category|
            if is_first then
              is_first = false
            else
              info += "\n"
            end
            info += sprintf("%-38s    %4s %4s %-19s %-3s\n",
                            category.name, "LIM", "REM", "RESET AT", "IN")
            category.each do |api|
              limits = api.limits
              info += sprintf("  %-38s: %4d %4d %19s %3d\n",
                              api.name, limits.limit, limits.remaining,
                              limits.reset_at.to_s[0, 19], limits.reset_in)
            end
          end
        else
          apiname.gsub!(/^\//, '')
          limits = self.client.apilimit().rate_limit(apiname).limits
          info += sprintf("API: %s\n", apiname)
          info += sprintf("    Limit     : %4d times\n",   limits.limit)
          info += sprintf("    Remaining : %4d times in 15 minutes.\n",
                                                           limits.remaining)
          info += sprintf("    Reset at  : %s\n",          limits.reset_at)
          info += sprintf("    Reset in  : %4d minutes\n", limits.reset_in)
        end
        self.renderer.puts(info)
        ret = 0
      rescue Tw::APILimit::NoAPINameError => e
        $stderr.puts experr(__FILE__, __LINE__, e)
        ret = 1
      rescue => e
        $stderr.puts experr(__FILE__, __LINE__, e)
        $stderr.puts Tw::BACKTRACE_MSG
        $stderr.puts(e.backtrace.join("\n")) if ENV["TWBT"]
        ret = 1
      end
      return ret
    end

  end

end
