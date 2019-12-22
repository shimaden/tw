# encoding: UTF-8

module Tw

  #==================================================================
  # 自分または誰かのフォロワーさんの ID を取得するクラス
  # 必ず API にアクセスしてしまう版
  #==================================================================
  class CacheableFriendsAndFollowersIds
    include Utility
    include Smdn::CGI

    #------------------------------------------------
    # イニシャライザ
    # 引数:
    #   requester:
    #       Tw::TwitterRequester 型
    #------------------------------------------------
    def initialize(requester, filename, permission, interval)
      if requester.is_a?(Tw::TwitterRequester) then
        @requester = requester
          TypeError.new("CacheableFriendsAndFollowers: requester must be Tw::TwitterRequester but #{requester.class}.")
      end
      @count    = nil
      if filename.nil? || permission.nil? || interval.nil? then
        # filename が指定されない場合は
        # ユーザ ID を API のみを使って取得し、配列に保持する。
        # 特に操作を行わない限り、保持したユーザ ID は更新されない。
        @idArray = Array.new()
      else
        # ユーザ ID を API から取得し、ファイルにキャッシュする。
        # ユーザ ID は、すでにキャッシュがあればキャッシュのデータを返す。
        # ユーザ ID を返すとき、キャッシュのデータが古くなっていれば
        # API から取得し直してキャッシュする。
        @idArray = FileCashableArray.new(filename, permission, interval)
      end
      @is_first_access = true
    end

      #------------------------------------------------
    protected
      #------------------------------------------------

    #------------------------------------------------
    # Get entpoint of Twitter API.
    #------------------------------------------------
    def get_endpoint()
    end

    #------------------------------------------------
    # Next cursor of the result for the followers/ids API
    #------------------------------------------------
    def next_cursor
      @result[:next_cursor]
    end

    #------------------------------------------------
    # Previous cursor of the result for the followers/ids API
    #------------------------------------------------
    def previous_cursor
      @result[:previous_cursor]
    end

    #------------------------------------------------
    # Count specified in the option parameter when invoked.
    #------------------------------------------------
    def count
      @count
    end

    def get(options)
      json = @requester.get(self.get_endpoint(), options)
      return json
    end

    #------------------------------------------------
    # 下請けメソッド
    # フォロワーの ID を取得して配列 @idArray に格納する
    # （1 回につき 5,000 件まで）。
    # 戻り値:
    #     Array of Integer
    #------------------------------------------------
    def one_page_from_api(options = {})
      begin
        @count = options[:count]
        @result = self.get(options)
        @idArray.concat(@result[:ids]) if !!@result[:ids]
      rescue Tw::Error => e
        $stderr.puts(experr(__FILE__, __LINE__, e))
        $stderr.printf(
          "  limit    : %d\n" \
          "  remaining: %d\n" \
          "  reset_at : %s\n" \
          "  reset_in : %d\n",
          e.rate_limit.limit,     # @attrs['x-rate-limit-limit']
          e.rate_limit.remaining, # @attrs['x-rate-limit-remaining']
          e.rate_limit.reset_at,  # @attrs['x-rate-limit-reset']
          e.rate_limit.reset_in   # [(reset_at - Time.now).ceil, 0].max
        )
      rescue => e
        $stderr.puts experr(__FILE__, __LINE__, e)
      ensure
        $stderr.puts "Count      : #{self.count},\n"           \
                   + "Prev cursor: #{self.previous_cursor},\n" \
                   + "Next cursor: #{self.next_cursor}"        \
                                              if ENV["TWDBG"] && ENV["TWCHK"]
      end

      return @idArray
    end

    #------------------------------------------------
    # API からすべてのフォロー／フォロワーさんの ID を
    # 取得して @idArray に格納する。
    #------------------------------------------------
    def all_followers_from_api()
      options = {
        :cursor => -1,
        :count  => 5000,
        :user_id => @requester.new_auth.user_id
      }

      is_continue = true
      while is_continue do
        self.one_page_from_api(options)
        options[:cursor] = self.next_cursor
        is_continue = (self.next_cursor > 0)
      end
      return @idArray
    end

    #------------------------------------------------
    # デバッグ用
    #------------------------------------------------
    def print_log(source, is_first_access, array_size)
      if ENV["TWDBG"] then
        $stderr.printf(
          "\nDBG>>> From %s, @is_first_access: %s, @idArray.size: %d\n\n",
          source, is_first_access, array_size)
      end
    end

    #------------------------------------------------
    # フォロワー ID の配列を必要なら新しくする。
    #------------------------------------------------
    def update_cache_when_expired()
      if @is_first_access then
        if @idArray.file_old? then
          self.clear()
          self.all_followers_from_api()
          @idArray.save_to_file()
          self.print_log("API", @is_first_access, @idArray.size)
        else
          @idArray.clear()
          @idArray.load_from_file()
          @idArray.map!{|str| Integer(str.to_i)}
          self.print_log("FILE", @is_first_access, @idArray.size)
        end
        @is_first_access = false
      else
        if @idArray.file_old? then
          self.clear()
          self.all_followers_from_api()
          @idArray.save_to_file()
          self.print_log("API", @is_first_access, @idArray.size)
        end
      end
    end

      #------------------------------------------------
    public
      #------------------------------------------------

    #------------------------------------------------
    # すべてのフォロワーのユーザ ID を取得して配列
    # @idArray に格納する。
    # 戻り値:
    #         Array of Integer
    #------------------------------------------------
    def get_all_followers_ids()
      self.update_cache_when_expired() if @idArray.is_a?(FileCashableArray)
      return @idArray
    end

    #------------------------------------------------
    # size of the internal array of IDs
    #------------------------------------------------
    def size()
      @idArray.size
    end

    #------------------------------------------------
    # Clear the internal array of IDs
    #------------------------------------------------
    def clear()
      if @idArray.not_nil? then
        @idArray.clear
      end
      @is_first_access = true
    end

    #------------------------------------------------
    # Parameters
    #   id: Weather followed by a specified user as a user id.
    #------------------------------------------------
    def followed_by?(id)
      self.update_cache_when_expired()
      return @idArray.include?(id)
    end

    #------------------------------------------------
    # Cache time
    #------------------------------------------------
    def last_update_time()
      return @idArray.last_update_time()
    end
    def cache_time()
tderr.puts("*** #{File.basename(__FILE__)}:#{__LINE__}: #cache_time() is obsolete. Use #last_update_time instead.")
      return self.last_update_time()
    end

  end

  # =================================================================
  # キャッシュ可能フォロワー ID
  # =================================================================
  class CacheableFollowersIds < CacheableFriendsAndFollowersIds
     END_POINT = '/1.1/followers/ids.json'
    def get_endpoint()
      return END_POINT
    end
  end

  # =================================================================
  # キャッシュ可能フレンド ID
  # =================================================================
  class CacheableFriendsIds < CacheableFriendsAndFollowersIds
    END_POINT = '/1.1/friends/ids.json'
    def get_endpoint()
      return END_POINT
    end
  end

  # =================================================================
  # キャッシュ可能ブロック・ユーザ ID
  # =================================================================
  class CacheableBlocksIds < CacheableFriendsAndFollowersIds
    END_POINT = '/1.1/blocks/ids.json'
    def get_endpoint()
      return END_POINT
    end
  end

  # =================================================================
  # キャッシュ可能ミュート・ユーザ ID
  # =================================================================
  class CacheableMutesIds < CacheableFriendsAndFollowersIds
    END_POINT = '/1.1/mutes/users/ids.json'
    def get_endpoint()
      return END_POINT
    end
  end

end
