# encoding: UTF-8
#
# Stream message types
# https://dev.twitter.com/docs/streaming-apis/messages

module Tw::Stream

  #------------------------------------------------------------------
  # User stream messages
  # https://dev.twitter.com/docs/streaming-apis/messages#User_stream_messages
  #------------------------------------------------------------------
  class Message
    def self.create(chunk)
      if !chunk.is_a?(Hash) then
        raise TypeError.new(errhlp(__FILE__, __LINE__,
                                        "chunk must be a Hash."))
      end
      if chunk[:delete] then
        return StatusDeletionNotice.new(chunk)
      elsif chunk[:limit] then
        return LimitNotice.new(chunk[:limit])
      elsif chunk[:disconnect] then
        return DisconnectMessage.new(chunk[:disconnect])
      elsif chunk[:target] then
        return AbstractEvent.create(chunk)
      else
        return false
      end
    end
    def to_s()
      "#{self.class}: to_s is not implemented in this class."
    end
    def to_json(*a)
      return "{}"
    end
  end

  #------------------------------------------------------------------
  # Friends lists (friends)
  #------------------------------------------------------------------
  class FriendsList < Tw::Stream::Message
    def initialize()
      super()
    end

    def set(chunk)
      if chunk.is_a?(Hash) then
        @friends = Array.new(chunk[:friends])
      elsif chunk.is_a?(Array) then
        @friends = chunk
      else
        raise ::TypeError.new("chunk must be Hash or Array but #{chunk.class}.")
      end
    end

    def [](idx)
      @friends[idx]
    end

    def size
      @friends.size
    end

    def following?(id)
      @friends.include?(id)
    end
  end

  #------------------------------------------------------------------
  # Status deletion notices (delete)
  #------------------------------------------------------------------
  class StatusDeletionNotice < Tw::Stream::Message
    attr_reader :status, :id, :user_id
    def initialize(chunk)
      super()
      if !chunk.has_key?(:delete) then
        raise ArgumentError.new(errhlp(__FILE__, __LINE__,
                                    "chunk doesn't has key: :delete."))
      end
      delete = chunk[:delete]
      @status   = delete[:status]
      @id       = delete[:status].not_nil?() ? delete[:status][:id]      : nil
      @user_id  = delete[:status].not_nil?() ? delete[:status][:user_id] : nil
      @chunk    = chunk
    end
    def to_s()
      "Status Deletion Notice: status_id: #{@id}, user_id: #{@user_id}"
    end
    def to_json(*a)
      return @chunk.to_json(*a)
    end
  end

  #------------------------------------------------------------------
  # Limit notices (limit)
  #------------------------------------------------------------------
  class LimitNotice < Tw::Stream::Message
    attr_reader :track
    def initialize(chunk)
      super()
      @track = chunk[:track]
      @chunk = chunk
    end
    def to_s()
      "Limit Notice: track #{@track}"
    end
    def to_json(*a)
      return @chunk.to_json(*a)
    end
  end

  #------------------------------------------------------------------
  # Disconnect messages (disconnect)
  #------------------------------------------------------------------
  class DisconnectMessage < Tw::Stream::Message
    attr_reader :code, :stream_name, :reason, :name, :description

    TABLE = [
      [nil, nil],
      ["Shutdown",
          "The feed was shutdown (possibly a machine restart"],
      ["Duplicate stream",
          "The same endpoint was connected too many times."],
      ["Control request",
          "Control streams was used to close a stream (applies to sitestreams)."],
      ["Stall",
          "The client was reading too slowly and was disconnected by the server."],
      ["Normal",
          "The client appeared to have initiated a disconnect."],
      ["Token revoked",
          "An oauth token was revoked for a user (applies to site and userstreams)."],
      ["Admin logout",
          "The same credentials were used to connect a new stream and the oldest was disconnected."],
      ["Reserved",
          "Reserved for internal use. Will not be delivered to external clients."],
      ["Max message limit",
          "The stream connected with a negative count parameter and was disconnected after all backfill was delivered."],
      ["Stream exception",
          "An internal issue disconnected the stream."],
      ["Broker stall",
          "An internal issue disconnected the stream."],
      ["Shed load",
          "The host the stream was connected to became overloaded and streams were disconnected to balance load. Reconnect as usual."]
    ].freeze

    def initialize(chunk)
      super()
      @code        = chunk[:code]
      @stream_name = chunk[:stream_name]
      @reason      = chunk[:reason]
      @name        = TABLE[@code][0].not_nil?() ? TABLE[@code][0] : nil
      @description = TABLE[@code][1].not_nil?() ? TABLE[@code][1] : nil
      @chunk       = chunk
    end

    def to_s()
      "Disconnect Message: code: #{@code}, stream name: #{@stream_name}, " \
          "reason: #{@reason}, name: #{@name}, description: #{@description}"
    end

    def to_json(*a)
      return chunk.to_json(*a)
    end

  end

  #------------------------------------------------------------------
  # Stall warnings (warning)
  #------------------------------------------------------------------
  class StallWarning < Tw::Stream::Message
    attr_reader :code, :message, :percent_full
    def initialize(chunk)
      super()
      @code         = chunk[:code]
      @message      = chunk[:message]
      @percent_full = chunk[:percent_full]
    end
    def to_s()
      "Stall Warning: code: #{@code}, message: #{@message}, " \
          "percent full: #{@percent_full}"
    end
  end

  #------------------------------------------------------------------
  # Abstract class for Event class
  #------------------------------------------------------------------
  class AbstractEvent < Tw::Stream::Message
    private_class_method :new
    attr_reader :target, :source, :event, :target_object, :created_at

    def self.create(chunk)
      if    chunk[:event] == "block"      then
        return Tw::Stream::UserBlocksSomeone.new(chunk)
      elsif chunk[:event] == "unblock"    then
        return Tw::Stream::UserRemovesABlock.new(chunk)
      elsif chunk[:event] == "favorite"   then
        return Tw::Stream::UserFavoritesATweet.new(chunk)
      elsif chunk[:event] == "unfavorite" then
        return Tw::Stream::UserUnfavoritesATweet.new(chunk)
      elsif chunk[:event] == "follow"     then
        return Tw::Stream::UserFollowsSomeone.new(chunk)
      elsif chunk[:event] == "unfollow"   then
        return Tw::Stream::UserUnfollowsSomeone.new(chunk)
      elsif chunk[:event] == "quoted_tweet" then
        return Tw::Stream::QuotedTweet.new(chunk)
      else
        return Tw::Stream::Event.new(chunk)
      end
    end

    def to_json(*a)
      return "{}"
    end
  end

  #------------------------------------------------------------------
  # Events (event)
  #   Notifications about non-Tweet events are also sent over a user stream. 
  #   These generally have the form of:
  #     {
  #       "target": TARGET_USER,
  #       "source": SOURCE_USER, 
  #       "event":"EVENT_NAME",
  #       "target_object": TARGET_OBJECT,
  #       "created_at": "Sat Sep 4 16:10:54 +0000 2010"
  #     }
  #------------------------------------------------------------------
  class Event < Tw::Stream::AbstractEvent
    public_class_method :new
    attr_reader :target, :source, :event, :target_object, :created_at,
                :s_user, :d_user

    def initialize(chunk)
      super()
      @target        = chunk[:target]
      @source        = chunk[:source]
      @event         = chunk[:event]
      @target_object = chunk[:target_object]
      @created_at    = chunk[:created_at]
      followed_by    = nil
      @s_user        = Tw::User.compose(
                            chunk[:source], followed_by)
      @t_user        = Tw::User.compose(
                            chunk[:target], followed_by)
      @chunk         = chunk
    end

    def to_s()
      sprintf("[%s] @%s %ss @%s.",
              @created_at, @s_user.screen_name, @event, @t_user.screen_name)
    end

    def to_json(*a)
      return @chunk.to_json(*a)
    end
  end

  #------------------------------------------------------------------
  # Event name   : access_revoked
  # Source       : Deauthorizing user
  # Target       : App owner
  # Target object: client_application
  #------------------------------------------------------------------
  class UserDeauthorizesStream < Tw::Stream::Event
  end

  #------------------------------------------------------------------
  # Event name   : block
  # Source       : Current user
  # Target       : Blocked user
  # Target object: Null
  #------------------------------------------------------------------
  class UserBlocksSomeone < Tw::Stream::Event
  end

  #------------------------------------------------------------------
  # Event name   : unblock
  # Source       : Current user
  # Target       : Unblocked user
  # Target object: Null
  #------------------------------------------------------------------
  class UserRemovesABlock < Tw::Stream::Event
  end

  #------------------------------------------------------------------
  # Event name   : favorite
  # Source       : Current user
  # Target       : Tweet author
  # Target object: Tweet
  #------------------------------------------------------------------
  class UserFavoritesATweet < Tw::Stream::Event
    def to_s()
      sprintf("[%s] @%s %ss @%s's %d.",
              @created_at,
              @s_user.screen_name, @event, @t_user.screen_name,
              @target_object[:id])
    end
  end

  #------------------------------------------------------------------
  # Event name   : favorite
  # Source       : Favoriting user
  # Target       : Current user
  # Target object: Tweet
  #------------------------------------------------------------------
  class UsersTweetIsFavorited < Tw::Stream::Event
  end

  #------------------------------------------------------------------
  # Event name   : unfavorite
  # Source       : Current user
  # Target       : Tweet author
  # Target object: Tweet
  #------------------------------------------------------------------
  class UserUnfavoritesATweet < Tw::Stream::Event
    def to_s()
      sprintf("[%s] @%s %ss @%s's %d.",
              @created_at,
              @s_user.screen_name, @event, @t_user.screen_name,
              @target_object[:id])
    end
  end

  #------------------------------------------------------------------
  # Event name   : unfavorite
  # Source       : Unfavoriting user
  # Target       : Current user
  # Target object: Tweet
  #------------------------------------------------------------------
  class UsersTweetIsUnfavorited < Tw::Stream::Event
  end

  #------------------------------------------------------------------
  # Event name   : follow
  # Source       : Current user
  # Target       : Followed user
  # Target object: Null
  #------------------------------------------------------------------
  class UserFollowsSomeone < Tw::Stream::Event
  end

  #------------------------------------------------------------------
  # Event name   : follow
  # Source       : Following user
  # Target       : Current user
  # Target object: Null
  #------------------------------------------------------------------
  class UserIsFollowed < Tw::Stream::Event
  end

  #------------------------------------------------------------------
  # Event name   : unfollow
  # Source       : Current user
  # Target       : Followed user
  # Target object: Null
  #------------------------------------------------------------------
  class UserUnfollowsSomeone < Tw::Stream::Event
  end

  #------------------------------------------------------------------
  # Event name   : list_created
  # Source       : Current user
  # Target       : Current user
  # Target object: List
  #------------------------------------------------------------------
  class UserCreatesAList < Tw::Stream::Event
  end

  #------------------------------------------------------------------
  # Event name   : list_destroyed
  # Source       : Current user
  # Target       : Current user
  # Target object: List
  #------------------------------------------------------------------
  class UserDeletesAList < Tw::Stream::Event
  end

  #------------------------------------------------------------------
  # Event name   : list_updated
  # Source       : Current user
  # Target       : Current user
  # Target object: List
  #------------------------------------------------------------------
  class UserEditsAList < Tw::Stream::Event
  end

  #------------------------------------------------------------------
  # Event name   : list_member_added
  # Source       : Current user
  # Target       : Added user
  # Target object: List
  #------------------------------------------------------------------
  class UserAddsSomeoneToAlist < Tw::Stream::Event
  end

  #------------------------------------------------------------------
  # Event name   : list_member_added
  # Source       : Adding user
  # Target       : Current user
  # Target object: List
  #------------------------------------------------------------------
  class UserIsAddedToAlist < Tw::Stream::Event
  end

  #------------------------------------------------------------------
  # Event name   : list_member_removed
  # Source       : Current user
  # Target       : Removed user
  # Target object: List
  #------------------------------------------------------------------
  class UserRemovesSomeoneFromAlist < Tw::Stream::Event
  end

  #------------------------------------------------------------------
  # Event name   : list_member_removed
  # Source       : Removing user
  # Target       : Current user
  # Target object: List
  #------------------------------------------------------------------
  class UserIsRemovedFromAlist < Tw::Stream::Event
  end

  #------------------------------------------------------------------
  # Event name   : list_user_subscribed
  # Source       : Current user
  # Target       : List owner
  # Target object: List
  #------------------------------------------------------------------
  class UserSubscribesToAList < Tw::Stream::Event
  end

  #------------------------------------------------------------------
  # Event name   : list_user_subscribed
  # Source       : Subscribing user
  # Target       : Current user
  # Target object: List
  #------------------------------------------------------------------
  class UsersListIsSubscribedTo < Tw::Stream::Event
  end

  #------------------------------------------------------------------
  # Event name   : list_user_unsubscribed
  # Source       : Current user
  # Target       : List owner
  # Target object: List
  #------------------------------------------------------------------
  class UserUnsubscribesFromAList < Tw::Stream::Event
  end

  #------------------------------------------------------------------
  # Event name   : list_user_unsubscribed
  # Source       : Unsubscribing user
  # Target       : Current user
  # Target object: List
  #------------------------------------------------------------------
  class UsersListIsUnsubscribedFrom < Tw::Stream::Event
  end

  #------------------------------------------------------------------
  # Event name   : quoted_tweet
  # Source       : Quoting user
  # Target       : Current user
  # Target object: Tweet
  #------------------------------------------------------------------
  class QuotedTweet < Tw::Stream::Event
  end

  #------------------------------------------------------------------
  # Event name   : user_update †
  # Source       : Current user
  # Target       : Current user
  # Target object: Null
  #------------------------------------------------------------------
  class UserUpdatesTheirProfile < Tw::Stream::Event
  end

  #------------------------------------------------------------------
  # Event name   : user_update †
  # Source       : Current user
  # Target       : Current user
  # Target object: Null
  #------------------------------------------------------------------
  class UserUpdatesTheirProtectedStatus < Tw::Stream::Event
  end

end
