# encoding: UTF-8
require 'time'
require File.expand_path 'user', File.dirname(__FILE__)

module Tw

  class List
    attr_reader :id, :name, :uri, :subscriber_count, :member_count, :mode,
                :description, :slug, :full_name, :created_at, :following,
                :user, :attr

    URI_BASE = "https://twitter.com"

    def initialize(list, followed_by)
      @id               = list[:id]
      @name             = list[:name]
      @uri              = list[:uri]
      @subscriber_count = list[:subscriber_count]
      @member_count     = list[:member_count]
      @mode             = list[:mode]
      @description      = list[:description]
      @slug             = list[:slug]
      @full_name        = list[:full_name]
      @created_at       = Time.parse(list[:created_at])
      @following        = list[:following]
      @user             = Tw::UserForList.new(list[:user], followed_by)
      @attrs            = list
    end

  end

  class UserForList < Tw::UserFromHash
    public_class_method :new

    def initialize(user, followed_by)
      super(user, followed_by)
      @notifications = user
    end

    def to_json(*a)
      list = super.to_json(*a)
      list[:notifications] = @notifications
      return list.to_json(*a)
    end

    def attrs()
      return @raw_data.to_json
    end

  end

  class ListAddRemoveResult
    attr_reader :id, :name, :uri, :subscriber_count, :member_count, :mode,
                :description, :slug, :full_name, :created_at, :following,
                :user, :attr

    def initialize(list, followers)
      @id               = list[:id]
      @name             = list[:name]
      @uri              = list[:uri]
      @subscriber_count = list[:subscriber_count]
      @member_count     = list[:member_count]
      @mode             = list[:mode]
      @description      = list[:description]
      @slug             = list[:slug]
      @full_name        = list[:full_name]
      @created_at       = Time.parse(list[:created_at])
      @following        = list[:following]
      @user             = Tw::User.compose(list[:user], followers.followed_by?(list[:user][:id]))
      @attrs            = list
    end

    def to_json(*a)
      hash = @attrs.dup
      hash[:created_at] = @created_at
      hash[:user]       = @user
      return hash.to_json(*a)
    end

  end

end
