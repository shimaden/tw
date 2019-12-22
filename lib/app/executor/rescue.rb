# encoding: UTF-8
module Tw::App

  class Executor < AbstractExecutor

  protected

  #**************************************************************************
  #
  #                                  Rescue
  #
  #**************************************************************************

    def show_rescue(file, line, method, e, params = {})

      if e.is_a?(Tw::Error) then
        code_page_not_exist    =  34
        code_suspended         =  63
        code_already_favorited = 139

        case e.code
        when code_suspended then  # Tw::Error::Forbidden
          user = ""
          if params[:user] then
            user = params[:user].is_a?(String) \
                 ? "@#{params[:user]}: " : "#{params[:user]}: "
          end
          $stderr.puts("#{user}#{e.code} #{e.message}")
          ret = TW_USER_SUSPENDED

        when code_page_not_exist then  # Tw::Error::NotFound
          status_id = params[:status_id] ? "#{params[:status_id]}: " : ""
          $stderr.puts("#{status_id}#{e.code} #{e.message}")
          ret = TW_PAGE_NOT_EXIST

        when code_already_favorited then
          status_id = params[:status_id] ? "#{params[:status_id]}: " : ""
          $stderr.puts("#{status_id}#{e.code} #{e.message}")
          ret = TW_ALREADY_FAVORITED

        when nil
          $stderr.puts(experr(file, line, e))
          ret = 1

        else
          $stderr.puts(experr(file, line, e))
          ret = 1

        end

      elsif e.is_a?(Tw::App::FileSaver::FileSaverError) then
        $stderr.puts("#{e.message}")
        ret = 1
      else
        $stderr.puts(experr(file, line, e))
        $stderr.puts(Tw::BACKTRACE_MSG)
        $stderr.puts(e.backtrace) if ENV["TWBT"]
        ret = 1
      end
      return ret
    end
  end

end
