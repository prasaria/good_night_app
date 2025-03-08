# app/services/followings/create_service.rb
module Followings
  class CreateService
    attr_reader :follower, :followed

    def initialize(follower:, followed:)
      @follower = follower
      @followed = followed
    end

    def call
      # Validate users are present
      raise Exceptions::BadRequestError, "Follower is required" if follower.nil?
      raise Exceptions::BadRequestError, "Followed user is required" if followed.nil?

      # Prevent self-following
      if follower.id == followed.id
        raise Exceptions::UnprocessableEntityError, "You cannot follow yourself"
      end

      # Check if already following
      if Following.exists?(follower: follower, followed: followed)
        raise Exceptions::UnprocessableEntityError, "You are already following this user"
      end

      # Create the following relationship
      following = Following.new(follower: follower, followed: followed)

      unless following.save
        error_message = following.errors.full_messages.join(", ")
        raise Exceptions::UnprocessableEntityError, error_message
      end

      # Return the following object directly
      following
    end
  end
end
