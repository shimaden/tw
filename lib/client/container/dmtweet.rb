# encoding: UTF-8
require 'time'
require File.expand_path 'user', File.dirname(__FILE__)
require File.expand_path 'entities/entities_for_tweet', File.dirname(__FILE__)

module Tw

  #----------------------------------------------------------------------
  # AbstractDMTweet class
  #----------------------------------------------------------------------
  class AbstractDMTweet
    private_class_method :new
    attr_reader :id, :text, # :full_text,
                :sender, :sender_id, :sender_screen_name,
                :recipient, :recipient_id, :recipient_screen_name,
                :created_at, :entities,
                :direction

    def entities?()
      @entities.not_nil?
    end

    def received?()
      return @direction == :received
    end

    def sent?()
      return @direction == :sent
    end

    def to_s()
      "#{@created_at}:@#{@sender_screen_name}>>" \
          "@#{@recipient_screen_name}: #{text}"
    end

    def to_json(*a)
      hash = @attrs.dup
      hash[:sender]     = @sender
      hash[:recipient]  = @recipient
      hash[:entities]   = @entities
      hash[:created_at] = @created_at
      return hash.to_json(*a)
    end

    def attrs()
      return @attrs
    end
  end

  #----------------------------------------------------------------------
  # DMTweet class
  #----------------------------------------------------------------------
  class DMTweet < AbstractDMTweet
    private_class_method :new

    def initialize(dm, direction, followed_by_sender, followed_by_recipient)
      super()
    end

    def self.compose(dm, direction, followed_by_sender, followed_by_recipient)
      if dm.is_a?(Hash) then
        return Tw::DMTweetFromHash.new(
                    dm, direction, followed_by_sender, followed_by_recipient)
      else
        raise TypeError.new("dm must be a Hash but #{dm.class}.")
      end
    end
  end

  #----------------------------------------------------------------------
  # DMTweetFromGem class
  #----------------------------------------------------------------------
  class DMTweetFromGem < DMTweet
    public_class_method :new

    def initialize(dm, direction, followed_by_sender, followed_by_recipient)
      super(dm, direction, followed_by_sender, followed_by_recipient)

      if !(direction == :received || direction == :sent) then
        raise RangeError.new(blderr(__FILE__, __LINE__,
                "direction must be one of :received and :sent."))
      end

      @id                    = dm.id
      @text                  = dm.text
      @sender                = Tw::User.compose(
                                          dm.sender,
                                          followed_by_sender)
      @sender_id             = dm.attrs[:sender_id]
      @sender_screen_name    = dm.attrs[:sender_screen_name]
      @recipient             = Tw::User.compose(
                                          dm.recipient,
                                          followed_by_recipient)
      @recipient_id          = dm.attrs[:recipient_id]
      @recipient_screen_name = dm.attrs[:recipient_screen_name]
      @created_at            = dm.created_at
      @entities              = Tw::Entities.compose(dm)
      @direction             = direction

      @attrs                 = dm.attrs()
    end
  end

  #----------------------------------------------------------------------
  # DMTweetFromHash class
  #----------------------------------------------------------------------
  class DMTweetFromHash < DMTweet
    public_class_method :new

    def initialize(dm, direction, followed_by_sender, followed_by_recipient)
      super(dm, direction, followed_by_sender, followed_by_recipient)

      if !(direction == :received || direction == :sent) then
        raise RangeError.new(blderr(__FILE__, __LINE__,
                "direction must be one of :received and :sent."))
      end

      @id                    = dm[:id]
      @text                  = dm[:text]
#      @full_text             = dm[:text]
      @sender                = Tw::User.compose(
                                          dm[:sender],
                                          followed_by_sender)
      @sender_id             = dm[:sender_id]
      @sender_screen_name    = dm[:sender_screen_name]
      @recipient             = Tw::User.compose(
                                          dm[:recipient],
                                          followed_by_recipient)
      @recipient_id          = dm[:recipient_id]
      @recipient_screen_name = dm[:recipient_screen_name]
      @created_at            = Time.parse(dm[:created_at])
      @entities              = Tw::Entities.compose(dm)
      @direction             = direction

      @attrs                 = dm
    end
  end

end
