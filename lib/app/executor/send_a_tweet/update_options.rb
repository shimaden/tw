# encoding: utf-8
# This helper module is used in the Tw::App:Executor#send_a_tweet() method.

module Tw::App

  #===========================================================
  # ツイート送信時のオプション
  #===========================================================
  class UpdateOptions
    attr_reader :update_options

    def initialize()
      @update_options = {}
    end

    def merge!(hash)
      @update_options.merge!(hash)
    end

    #---------------------------------------------------------
    # In-reply-to status ID が指定されている場合。
    # In-reply-to status ID.
    #---------------------------------------------------------
    def set_in_reply_to_status_id(in_reply_to_status_id)
      if !(in_reply_to_status_id.is_a?(Integer) || in_reply_to_status_id.nil?) then
        raise ::TypeError.new("in_reply_to_status_id must be an Integer value but #{in_reply_to_status_id.class}.")
      end
      return if !in_reply_to_status_id

      # 返信先のツイートの status_id である in_reply_to を設定。
      @update_options[:in_reply_to_status_id] = in_reply_to_status_id

      # これをセットするとツイッターは @mentions を
      # 文字数にカウントせず、hidden prefix に格納する。
      # Twitter doesn't count the number of characters of @mentions
      # as strings in the text.
      @update_options[:auto_populate_reply_metadata] = true
    end

    #---------------------------------------------------------
    # media_id
    #---------------------------------------------------------
    def media_ids=(media_ids)
      @update_options[:media_ids] = media_ids
    end
    def media_ids()
      return @update_options[:media_ids]
    end
    def media_ids?
      return !!@update_options[:media_ids]
    end

    #---------------------------------------------------------
    # Quote tweet url
    #---------------------------------------------------------
    def attachment_url=(url)
      @update_options[:attachment_url] = url
    end

    #---------------------------------------------------------
    # Disable new style reply (@mentions are non counted as a part of
    # 140-character tweet).
    #---------------------------------------------------------
    def disable_auto_populate_reply_metadata=(value)
      if @update_options.has_key?(:in_reply_to_status_id) then
        @update_options[:auto_populate_reply_metadata] = !value
      end
    end

    #---------------------------------------------------------
    # Set exclude reply user ids
    #---------------------------------------------------------
    def set_exclude_reply_user_ids(exclude_user_ids, in_reply_to_status, scraped_users, is_exclude_scraped_users: true)
      if !@update_options[:in_reply_to_status_id] then
        ::RuntimeError.new("@update_options[:in_reply_to_status_id] is not set yet.")
      end
      return [] if exclude_user_ids.size == 0 && scraped_users.size == 0 
      @update_options[:is_exclude_scraped_users] = is_exclude_scraped_users

      if in_reply_to_status.entities.user_mentions? then
        user_mentions = in_reply_to_status.entities.user_mentions
      else
        user_mentions = []
      end

      # in_reply_to_status の hidden mentions から、コマンド
      # ラインで指定されたユーザを除外する。
      exclude_user_arr = []
      exclude_user_ids.each{|user|
        user_to_exclude = in_reply_to_status.hidden_mentions.to_a \
                .concat(user_mentions.to_a) \
                .concat(scraped_users.to_a).find{|mention|
          if user =~ /^[0-9]+$/ then
            result = (mention.id == Integer(user))
          else
            result = ("@#{mention.screen_name.downcase}" == user.downcase)
          end
          result
        }
        exclude_user_arr.push(user_to_exclude) if user_to_exclude != nil
      }

      if is_exclude_scraped_users then
        exclude_user_arr.concat(scraped_users.to_a)
      end

      return [] if exclude_user_arr.size == 0

      @update_options[:exclude_reply_user_ids] = exclude_user_arr.collect{|u| u.id}.uniq.join(',')
      result = exclude_user_arr.collect{|u| "@#{u.screen_name}"}.uniq

      return result
    end

    #---------------------------------------------------------
    # Additional owners for media and video upload.
    #---------------------------------------------------------
    def additional_owners()
      return @additional_owners
    end
    def additional_owners=(val)
      @update_options[:additional_owners] = val
    end

  end

end
