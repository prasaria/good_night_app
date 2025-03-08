# app/controllers/api/v1/followings_controller.rb
module Api
  module V1
    class FollowingsController < BaseController
      # POST /api/v1/followings
      def create
        validator = FollowingsValidator.new(params)
        validator.validate_create_action

        following = Followings::CreateService.new(
          follower: validator.follower,
          followed: validator.followed
        ).call

        render_success({
          following: FollowingSerializer.new(following, include_users: true).as_json
        }, :created)
      end

      # DELETE /api/v1/followings/:id
      # or
      # DELETE /api/v1/followings with follower_id and followed_id params
      def destroy
        validator = FollowingsValidator.new(params)
        validator.validate_destroy_action

        following = validator.following

        # Use the RemoveService to ensure proper error handling and business logic
        _result = Followings::RemoveService.new(
          id: following.id
        ).call

        # Return 204 No Content with empty body for successful deletions
        head :no_content
      end
    end
  end
end
