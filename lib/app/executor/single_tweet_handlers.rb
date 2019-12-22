# encoding: UTF-8
module Tw::App

  class Executor < AbstractExecutor

    #protected
    public

  #**************************************************************************
  #
  #        Single Tweet Handlers: Read / Send / Retweet / Favorite
  #
  #**************************************************************************

    #----------------------------------------------------------------
    # Show statuses.
    #   ignore_unauthorized_exception: ツイート取得時の非承認例外を無視
    #   status_arr: 表示したいツイートの配列。これが指定されていると
    #               API からツイートを取得する代わりに、配列内のツイートを
    #               表示する。
    #----------------------------------------------------------------
    def status(optname, optarg, ignore_unauthorized_exception: false, status_arr: [])
      if !status_arr.is_a?(::Array) then
        raise ::TypeError.new("status_arr must be Array of Tw::Tweet but #{status_arr.class}")
      end
      idx = status_arr.find_index{|e| !e.is_a?(Tw::Tweet)}
      if idx != nil then
        raise ::TypeError.new("Element ##{i} of Array status_arr is not Tw::Tweet but #{status_arr[idx].class}")
      end

      ret = RetCode.new()
      begin
        ret_arr   = []
        twTweets  = []
        exceptions = []

        # Tw::Tweet が配列として外部から与えられていない場合
        if status_arr.nil? || status_arr.size == 0 then
          # 普通にツイッターからツイートを取得して
          # 配列 twTweets に追加
          status_id = nil
          self.get_id_array(optarg).each do |id|
            status_id = Integer(id)
            tw, excep = self.get_a_status(id) # ツイートを取得
            exceptions.push(excep) if excep != nil
            if tw.nil? then
              ret_arr << 1
            else
              twTweets.push(tw) # ツイートを格納
            end
          end
          if ret_arr.empty? then
            ret.code = 0
          elsif ret_arr.size == 1 then
            ret.code = ret_arr[0]
          else
            ret.add_sub_code(ret_arr)
          end
        else # 外部から Tw::Tweet が配列として与えられている場合
          # やはり配列 twTweets に追加。
          twTweets.concat(status_arr) if status_arr.size > 0
          ret.code = 0
        end

        # JSON で保存、または画面に表示
        if @options.save_as_json? then # JSON で保存
          fs = FileSaver.create(@options.save_as_json(), "w", :json)
          fs.save(twTweets)
        else                           # 画面に表示
          ret_arr = []
          twTweets.each do |tw|
            ret_arr << self.show_a_status(tw)  # ツイートを表示する。
          end
          ret.add_sub_code(ret_arr)
        end

        if exceptions.size > 0 then
          if ignore_unauthorized_exception then
            exceptions.each do |e|
              $stderr.puts("(Ignore) #{e.code} #{e.message}")
            end
          else
            raise e[0]
          end
        end

      rescue ::TypeError
        raise
      rescue CmdOptionError
        raise
      rescue SystemCallError
        raise
      rescue Tw::Error
        raise
      rescue => e
        ret.code = self.show_rescue(__FILE__, __LINE__, __method__, e,
                                  {:status_id => status_id})
      ensure
        if fs.is_a?(FileSaver) then
          fs.close()
        end
      end
      return ret
    end

    #----------------------------------------------------------------
    # Tweet a message
    #----------------------------------------------------------------
    def tweet(optname, optarg)
      ret = RetCode.new()
      message = optarg.decode_line_feed()
      result = []

      rep_id_array = self.get_id_array(@options.in_reply_to()).collect{|id| [id, false]}
      rep_id_array.concat(self.get_id_array(@options.in_reply_to_new()).collect{|id| [id, true]})
      if rep_id_array.size > 0 then
        rep_id_array.each do |in_reply_to_status_id, is_auto_populate_reply|
          result << self.send_a_tweet(message, in_reply_to_status_id, is_auto_populate_reply)
        end
      end
      if rep_id_array.size == 0 then
        result << self.send_a_tweet(message, nil, false)
      end

      if result.size == 1 then
        ret.code = result[0]
      elsif result.size >= 2 then
        ret.add_sub_code(result)
      end
      return ret
    end

    #----------------------------------------------------------------
    # Tweet a message from the standard input.
    #----------------------------------------------------------------
    def pipe(optname, optarg)
      is_ocra = ENV.key?("OCRA_EXECUTABLE")
      pipe_in = $stdin.dup()
      pipe_in.set_encoding(Encoding::CP932, Encoding::UTF_8) if is_ocra
      $stdin.close()
      begin
        tty_name = is_ocra ? "CON" : "/dev/tty"
        $stdin.reopen(tty_name, "r")
      rescue Errno::ENXIO => e  # ここは SystemCallError に置き換えない
        $stderr.puts("#{::CLIENT_NAME}: #{e.class}: #{e.message}: assume --asume-yes specified.")
        $stderr.puts("#{::CLIENT_NAME}: Perhaps executed in cron or at command.")
        @options.assume_yes = true
      end

      rep_id_array = "#{@options.in_reply_to()}".split(",").collect{|id| [Integer(id), false]}
      rep_id_array.concat("#{@options.in_reply_to_new()}".split(",").collect{|id| [Integer(id), true]})
      ret = RetCode.new()
      result = []
      msg_ary = pipe_in.read.split(/^\/EX\n/i).reject {|msg| msg == ""}
      msg_ary.each do |message|
        if rep_id_array.size > 0 then
          rep_id_array.each do |in_reply_to, is_auto_populate_reply|
            result << self.send_a_tweet(message, in_reply_to, is_auto_populate_reply)
          end
        end
        if rep_id_array.size == 0 then
          result << self.send_a_tweet(message, nil, false)
        end
      end
      if result.size == 1 then
        ret.code = result[0]
      elsif result.size >= 2 then
        ret.add_sub_code(result)
      end
      return ret
    end

    #----------------------------------------------------------------
    # Retweet.
    #----------------------------------------------------------------
    def retweet(optname, optarg)
      ret = RetCode.new()
      result = []
      self.get_id_array(optarg).each do |id|
        result << self.retweet_a_tweet(id)
      end
      if result.size == 1 then
        ret.code = result[0]
      elsif result.size >= 2 then
        ret.add_sub_code(result)
      end
      return ret
    end

    #----------------------------------------------------------------
    # Unetweet.
    #----------------------------------------------------------------
    def unretweet(optname, optarg)
      ret = RetCode.new()
      result = []
      self.get_id_array(optarg).each do |id|
        result << self.unretweet_a_tweet(id)
      end
      if result.size == 1 then
        ret.code = result[0]
      elsif result.size >= 2 then
        ret.add_sub_code(result)
      end
      return ret
    end

    #----------------------------------------------------------------
    # Favorite.
    #----------------------------------------------------------------
    def favorite(optname, optarg)
      ret = RetCode.new()
      result = []
      self.get_id_array(optarg).each do |id|
        result << self.favorite_a_tweet(id)
      end
      if result.size == 1 then
        ret.code = result[0]
      elsif result.size >= 2 then
        ret.add_sub_code(result)
      end
      return ret
    end

    #----------------------------------------------------------------
    # Unfavorite.
    #----------------------------------------------------------------
    def unfavorite(optname, optarg)
      ret = RetCode.new()
      result = []
      self.get_id_array(optarg).each do |id|
        result << self.unfavorite_a_tweet(id)
      end
      if result.size == 1 then
        ret.code = result[0]
      elsif result.size >= 2 then
        ret.add_sub_code(result)
      end
      return ret
    end

    #----------------------------------------------------------------
    # Destroy status.
    #----------------------------------------------------------------
    def destroy_status(optname, optarg)
      ret = RetCode.new()
      result = []
      self.get_id_array(optarg).each do |id|
        result << self.destroy_a_status(id, :trim_user => true)
      end
      if result.size == 1 then
        ret.code = result[0]
      elsif result.size >= 2 then
        ret.add_sub_code(result)
      end
      return ret
    end
  end

end
