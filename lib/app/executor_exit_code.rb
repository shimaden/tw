# encoding: UTF-8
# このファイルはＵＴＦ－８です。
module Tw::App

  class Executor < AbstractExecutor
    EXIT_BY_NO          = 10  # exit status code when selected 'No' in 'Yes/No.'
    MULTI_CALL_ERR      = 11  # if error returned when multiple functions executed.
    INVALID_COMMAND_ERR = 12  # command given is not valid.
    TOO_FEW_ARGS_ERR    = 13  # invalid number of arguments.
    TOO_MANY_ARGS_ERR   = 14  # invalid number of arguments.
    INVALID_ARG_ERR     = 15  # bad type of argument
    BROKEN_PIPE         = 16
    NO_SUCH_FILE_OR_DIR = 17
    OPTION_ARG_ERR      = 18  # Specified argument is wrong for this option.
    SYSTEM_CALL_ERROR   = 19  # Error:: で始まる例外
    ECONNRESET          = 20

    # Twitter errors.
    TW_UNAUTHORIZED        = 51
    TW_PAGE_NOT_EXIST      = 52
    TW_USER_SUSPENDED      = 53
    TW_ALREADY_RETWEETED   = 54
    TW_ALREADY_FAVORITED   = 55
    TW_SERVICE_UNAVAILABLE = 56

    # HTTP errors.
    HTTP_NOT_FOUND             = 101
    HTTP_FORBIDDEN             = 102
    HTTP_REQUEST_TIMEOUT       = 103
    HTTP_INTERNAL_SERVER_ERROR = 104
    HTTP_TOO_MANY_REQUESTS     = 105
    HTTP_BAD_REQUEST           = 106

    # Network error.
    NETWORK_ERROR          = 151

    class RetCode
      # Exit codes

      def initialize(code = 0, sub_code = [])
        super()
        @code = code
        @sub_code = [].concat(sub_code)
      end

      def code()
        self.multi_call_err?
        return @code
      end
      def code=(val)
        if !val.is_a?(Integer) then
          raise TypeError.new(blderr(__FILE__, __LINE__, "RetCode#code: #{val.class} given. Val must be an Integer."))
        end
        @code = val
        return @code
      end
      def add_sub_code(val)
        if val.is_a?(Integer) then
          @sub_code.push(val)
        elsif val.is_a?(Array) then
          @sub_code.concat(val)
        else
          raise TypeError.new(blderr(__FILE__, __LINE__, "RetCode.add_sub_code: val must be an Integer or an Array of Integer."))
        end
      end
      def sub_code()
        return @sub_code
      end
      def multi_call_err?
        ret = false
        if @code == MULTI_CALL_ERR then
          ret = true
        end
        if @sub_code.any? {|errcode| errcode != 0} then
          @code = MULTI_CALL_ERR
          ret = true
        end
        return ret
      end
    end

  end

end
