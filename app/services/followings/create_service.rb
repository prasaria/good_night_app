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
      return ServiceResult.failure("Follower is required") if follower.nil?
      return ServiceResult.failure("Followed user is required") if followed.nil?

      # Prevent self-following
      if follower.id == followed.id
        return ServiceResult.failure("You cannot follow yourself")
      end

      # Check if already following
      if Following.exists?(follower: follower, followed: followed)
        return ServiceResult.failure("You are already following this user")
      end

      # Create the following relationship
      following = Following.new(follower: follower, followed: followed)

      if following.save
        ServiceResult.success(following: following)
      else
        ServiceResult.failure(following.errors.full_messages)
      end
    end
  end
end
