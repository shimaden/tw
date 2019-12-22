# encoding: UTF-8

module Tw

  #==================================================================
  # ユーザ情報を取得するクラス
  #==================================================================
  class UserGetter
    include Smdn::CGI

    END_POINT = '/1.1/users/show.json'

    #-------------------------------------------------------
    # followersIds:
    #   CacheableFollowersIds
    #     use CacheableFollowersIds to set the followed_by
    #     parameter of Tw::User.
    #   nil
    #     call API directly # by using the FollowersIDsCursor
    #     lass.
    #-------------------------------------------------------
    def initialize(requester, followersIds)
      options = nil
      if requester.is_a?(Tw::TwitterRequester) then
        @requester = requester
      else
        raise ::TypeError.new("Use Tw::TwitterRequest and not #{requester.class} for requester.")
      end
      if !!followersIds then
        @followersIds = followersIds
      else
        @followersIdsCursor = FollowersIDsCursor.new(requester, requester.new_auth.user.id, options)
      end
    end

    protected

    def followed_by?(user_id)
      if !!@followersIds then
        followed_by = @followersIds.followed_by?(user_id)
      else
        followed_by = @followersIdsCursor.include?(user_id)
      end
      return followed_by
    end

    public

    #-------------------------------------------------------
    # GET users/show
    # Returns a variety of information about the user specified by the 
    # required user_id or screen_name parameter. The author's most recent 
    # Tweet will be returned inline when possible.
    #
    # Parameters
    #   user_id:
    #       The ID of the user for whom to return results for. Either an 
    #       id or screen_name is required for this method.
    #   screen_name:
    #       The screen name of the user for whom to return results for. 
    #       Either a id or screen_name is required for this method.
    #   include_entities:
    #       The entities node will be disincluded when set to false.
    #
    # Return Value
    #   An object of the Tw::User class.
    #
    # Exceptions
    #   ArgumentError at least.
    #-------------------------------------------------------
    def users_show(user, options = {})
      if user.is_a?(String) then
        options[:screen_name] = user
      elsif user.is_a?(Integer) then
        options[:user_id] = user
      else
        raise ArgumentError.new("#{bn(__FILE__)}(#{__LINE__}): " \
            "user must be an Ingeter or String " \
            "but #{user.class} is given.")
      end
      user_hash = @requester.get(END_POINT, options)
      followed_by = self.followed_by?(user_hash[:id])
      return Tw::User.compose(user_hash, followed_by)
    end

  end

end
