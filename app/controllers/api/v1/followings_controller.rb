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
    end
  end
end
