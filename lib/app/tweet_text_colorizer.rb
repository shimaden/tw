# encoding: UTF-8
#require File.expand_path 'tweet_kind', File.dirname(__FILE__)

module Tw::App

  # ツイート本文に色をつける。
  class TweetTextColorizer
      GREEN     = "\e[32;1m"
      MAGENTA   = "\e[35m"
      YELLOW    = "\e[33m"
      BLUE      = "\e[38;5;#{"4B".to_i(16)}m"
      BLUE_BOLD = "\e[38;5;#{"4B".to_i(16)};1m"
      DARK_WHITE = "\e[38;5;#{"F5".to_i(16)}m"

      UNDERLINE = "\e[4m"

      CLEAR     = "\e[0m"

      #CLEAR_REG = /\e\[0m/

    def initialize(tweet)
      @tweet = tweet
    end

    protected

    #----------------------------------------------------------------------
    # Return which tweet and text to render.
    #----------------------------------------------------------------------
    def select_tweet_and_text()
      result = nil
      if @tweet.kind.regular_tweet? || @tweet.kind.result_of_retweet? then
        text = @tweet.new_140_count_feature? ? @tweet.full_text : @tweet.text
        result = {:tweet => @tweet, :text => text}
      elsif @tweet.kind.retweet? then
        if @tweet.retweeted_status.new_140_count_feature? then
          text = @tweet.retweeted_status.full_text
        else
          text = @tweet.retweeted_status.text
        end
        result = {:tweet => @tweet.retweeted_status, :text => text}
      end
      return result
    end

    #----------------------------------------------------------------------
    # Whether need to color or not.
    #----------------------------------------------------------------------
    def need_to_color?(selected_tweet)
      entities = selected_tweet[:tweet].entities

      is_nil = entities.user_mentions.nil? \
            && entities.hashtags.nil?      \
            && entities.symbols.nil?
      if is_nil then
        return false
      end

      has_stuff = entities.user_mentions.size > 0 \
               || entities.hashtags.size > 0      \
               || entities.symbols.size > 0

      return has_stuff
    end

    #----------------------------------------------------------------
    # 本文に色を付ける関数の下請け。
    # dest_obj     = {:dest_str => dest}
    # sub_params = {
    #     :dest_str => dest, :index_arr => indexArr,
    #     :need_to_color => in_status, :last_index => last,
    #     :color => color, :clear_color => clear_color
    # }
    #----------------------------------------------------------------
    def append_color_esc(i, dest_obj, sub_params, dbgopt = false)
      if sub_params[:need_to_color] then # 色をつける必要がある場合
        dest_obj[:dest_str]  += sub_params[:color] # ESC シーケンスを追加
        sub_params[:counter] += 1 # カウンターをインクリメント
      else                           # 色つけ対象の文字列の中にいない
        if i > 0 then   # 0 文字目以降にいる
          dest_obj[:dest_str] += sub_params[:clear_color] # 色を消す ESC を追加
          sub_params[:counter] = 0  # カウンターをリセット
        end
      end
      sub_params[:last_index] = sub_params[:index_arr].shift # :index_arr の最初の要素
      sub_params[:need_to_color] = !sub_params[:need_to_color]
    end

    #----------------------------------------------------------------------
    # Color text.
    #----------------------------------------------------------------------
    def colorize(selected_tweet)
      src_text = selected_tweet[:text]
      entities = selected_tweet[:tweet].entities

      user_mentions_start = entities.user_mentions.collect{|e| e.indices[0]}
      hashtags_start      = entities.hashtags.collect{|e| e.indices[0]}
      symbols_start       = entities.symbols.collect{|e| e.indices[0]}

      user_mentions_end = entities.user_mentions.collect{|e| e.indices[1]}
      hashtags_end      = entities.hashtags.collect{|e| e.indices[1]}
      symbols_end       = entities.symbols.collect{|e| e.indices[1]}

      dest_text = ""
      is_cleared = true
      src_text.split(//).each.with_index do |char, i|
        if    !!user_mentions_end.include?(i) \
           || !!hashtags_end.include?(i) \
           || !!symbols_end.include?(i)  then
          dest_text += CLEAR
          is_cleared = true
        end
        if !!user_mentions_start.include?(i) then
          dest_text += BLUE  + UNDERLINE
          is_cleared = false
        end
        if !!hashtags_start.include?(i) then
          dest_text += GREEN + UNDERLINE
          is_cleared = false
        end
        if !!symbols_start.include?(i) then
          dest_text += GREEN + UNDERLINE
          is_cleared = false
        end
        dest_text += char
      end
      dest_text += CLEAR if !is_cleared

      return dest_text
    end

    public

    #----------------------------------------------------------------------
    # Return colorized text
    # If colorize is true, colorize it and return colorized text.
    # If false, return an appropriate text to render but not colorized.
    #----------------------------------------------------------------------
    def perform(do_colorize)
      stat = $stdout.stat()
      selected_tweet = self.select_tweet_and_text()
      tweet = selected_tweet[:tweet]
      result = nil

      if stat.file? || stat.pipe? then
        result = selected_tweet[:text]
      else
        if do_colorize && self.need_to_color?(selected_tweet) then
          result = self.colorize(selected_tweet)
          if tweet.hidden_prefix? || tweet.hidden_suffix? then
            result = self.get_substr(result, tweet.display_text_range)
          end
        else
          result = selected_tweet[:text]
          if tweet.hidden_prefix? || tweet.hidden_suffix? then
            range = tweet.display_text_range
            result = result[range[0], range[1] - range[0]]
          end
        end
      end
      
      return result
    end

    protected

    def build_structured_text(colored_text)
      structured_text = Hash.new("")
      physical_idx = 0
      logical_idx  = 0
      while physical_idx < colored_text.length do
        if colored_text[physical_idx] == "\e" then
          structured_text[logical_idx] += colored_text[physical_idx]
          physical_idx += 1
          while colored_text[physical_idx] != "m" do
            structured_text[logical_idx] += colored_text[physical_idx]
            physical_idx += 1
            break if physical_idx >= colored_text.length
          end
          structured_text[logical_idx] += colored_text[physical_idx]
          physical_idx += 1
        else
          structured_text[logical_idx] += colored_text[physical_idx]
          physical_idx += 1
          logical_idx  += 1
        end
      end
      return structured_text
    end

    def build_dest_text(structured_text, pos1, pos2)
      result = ""
      i = pos1
      while i < pos2 do
        result += structured_text[i]
        i += 1
      end
      last_str = /(\e[^m]+m)*/.match(structured_text[pos2]).to_a.last
      if last_str == CLEAR then
        result += structured_text[pos2]
      end
      return result
    end

    public

    def get_substr(colored_text, pos_arr)
      structured_text = self.build_structured_text(colored_text)
      dest_str = self.build_dest_text(structured_text, pos_arr[0], pos_arr[1])
      return dest_str
    end

  end
end
