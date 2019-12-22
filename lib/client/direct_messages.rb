# encoding: UTF-8
require File.expand_path 'container/dmtweet', File.dirname(__FILE__)
require File.expand_path('../utility/cgi_escape', File.dirname(__FILE__))

module Tw

  #*******************************************************************
  # DirectMessages class
  #*******************************************************************
  class DirectMessages
    include Smdn::CGI

    MAX_COUNT          = 800
    MAX_COUNT_PER_CALL = 200

    def initialize(requester, followers)
      @requester = requester
      @followers = followers
    end

    def get_direct_messages(count)
      loop_count_max     = count.div(MAX_COUNT_PER_CALL)
      last_request_count = count.modulo(MAX_COUNT_PER_CALL)
      if last_request_count > 0 then
        loop_count_max += 1
      end

      received_dm_arr = []

      loop_count = 1
      request_count = MAX_COUNT_PER_CALL
      while loop_count <= loop_count_max do
        if loop_count == loop_count_max then
          request_count = last_request_count
        end

        options = {
          :count            => request_count,
          :include_entities => true,
          :full_text        => true
        }
        received_dm_arr.concat(self.do_get_direct_message(options))

        loop_count += 1
      end
      return received_dm_arr
    end

  end

  #*******************************************************************
  # ReceivedDirectMessages class
  #*******************************************************************
  class ReceivedDirectMessages < Tw::DirectMessages

    END_POINT = '/1.1/direct_messages.json'

    # GET direct_messages
    # https://dev.twitter.com/docs/api/1.1/get/direct_messages
    def do_get_direct_message(options)
      json_arr = @requester.get(END_POINT, options)
      twDmArray = json_arr.map do |dm|
        Tw::DMTweet.compose(
                    dm,
                    :received,
                    @followers.followed_by?(dm[:sender][:id]),   # (dm.sender.id),
                    @followers.followed_by?(dm[:recipient][:id]) # (dm.recipient.id))
        )
      end
      return twDmArray
    end
  end

  #*******************************************************************
  # SentDirectMessages
  #*******************************************************************
  class SentDirectMessages < Tw::DirectMessages

    END_POINT = '/1.1/direct_messages/sent.json'

    # GET direct_messages/sent
    # https://dev.twitter.com/docs/api/1.1/get/direct_messages/sent
    def do_get_direct_message(options)
      json_arr = @requester.get(END_POINT, options)
      twDmArray = json_arr.map do |dm|
        Tw::DMTweet.compose(
                    dm,
                    :sent,
                    @followers.followed_by?(dm[:sender][:id]),   # (dm.sender.id),
                    @followers.followed_by?(dm[:recipient][:id]) # (dm.recipient.id))
        )
      end
      return twDmArray
    end
  end

end
