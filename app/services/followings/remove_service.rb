# app/services/followings/remove_service.rb
module Followings
  class RemoveService
    attr_reader :follower, :followed, :id

    def initialize(follower: nil, followed: nil, id: nil)
      @follower = follower
      @followed = followed
      @id = id
    end

    def call
      # Validate parameters
      if id.nil? && (follower.nil? || followed.nil?)
        if follower.nil? && followed.nil?
          return ServiceResult.failure("Must provide either following ID or both follower and followed users")
        else
          return ServiceResult.failure("Must provide both follower and followed users")
        end
      end

      # Find the following relationship
      following = find_following

      # Check if following exists
      unless following
        return ServiceResult.failure("Following relationship not found")
      end

      # Attempt to remove the following
      if following.destroy
        ServiceResult.success(message: "Successfully unfollowed #{following.followed.name}")
      else
        ServiceResult.failure("Failed to unfollow user")
      end
    end

    private

    def find_following
      if id
        Following.find_by(id: id)
      else
        Following.find_by(follower: follower, followed: followed)
      end
    end
  end
end
