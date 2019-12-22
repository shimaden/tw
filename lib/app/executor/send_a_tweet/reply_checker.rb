# encoding: UTF-8
# このファイルはＵＴＦ－８です。

module Tw::App

  #================================================================
  # ReplyChecker
  #================================================================
  class ReplyChecker
    attr_reader :screen_names_in_message

    SCREEN_NAME_REG = /((?<![a-zA-Z0-9_\!#$%&@\*])@[a-zA-Z0-9_]+)/i

    module ScreenNameInclude
      def include_screen_name?(screen_name)
        if screen_name.is_a?(Array) then
          return !!self.find{|sn1| screen_name.find{|sn2| sn1.downcase == sn2.downcase}}
        else
          return !!self.find{|sn| sn.downcase == screen_name.downcase}
        end
      end
    end

    def initialize(in_reply_to_status, message_to_post)
      @in_reply_to_status = in_reply_to_status
      @message_to_post    = message_to_post
      @screen_names_in_message = @message_to_post.screen_names_in_text()
      @mention_users_in_reply_tweet = @in_reply_to_status.entities.user_mentions.map{|sn|
        "@#{sn.screen_name}"
      }
      @screen_names_in_message.extend(ScreenNameInclude)
      @mention_users_in_reply_tweet.extend(ScreenNameInclude)
    end
    protected
    public
    #---------------------------------------------------------------
    # 自分のツイート宛てのリプになってるか
    #---------------------------------------------------------------
    def reply_to_my_tweet?
      return @in_reply_to_status.user.id == @message_to_post.poster_user_id
    end
    #---------------------------------------------------------------
    # 本文に自分以外の人宛の @mentions を持っているか
    #---------------------------------------------------------------
    def reply_has_mentions_to_someone_else?
      found = @mention_users_in_reply_tweet.include_screen_name?("@#{@message_to_post.poster_screen_name}")
      return found
    end
    #---------------------------------------------------------------
    # 本文にリプ宛先の TW の送信者の @mention が入っているか、
    # またはリプ宛先 TW とこっちのメッセージ本文に共通の @mention が
    # あるか
    #---------------------------------------------------------------
    def message_has_mention_in_reply_target?
      return @screen_names_in_message.include_screen_name?(["@#{@in_reply_to_status.user.screen_name}"].concat(@mention_users_in_reply_tweet))
    end
    #---------------------------------------------------------------
    # 本文にリプライ対象のツイートの送信者の @mention が入っているか
    #---------------------------------------------------------------
    def message_has_screen_name_of_reply_poster?
      return @screen_names_in_message.include_screen_name?("@#{@in_reply_to_status.user.screen_name}")
    end
    #---------------------------------------------------------------
    # この TW の本文にある @mentions がリプ宛先の TW にあるか
    #---------------------------------------------------------------
    def reply_has_screen_name_that_message_has?
      return @screen_names_in_message.include_screen_name?(@mention_users_in_reply_tweet)
    end
  end

end
