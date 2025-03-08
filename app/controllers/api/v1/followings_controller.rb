# app/controllers/api/v1/followings_controller.rb
module Api
  module V1
    class FollowingsController < BaseController
      # GET /api/v1/followings
      def index
        validator = FollowingsValidator.new(params)
        validator.validate_index_action

        result = Followings::ListService.new(
          user: validator.user,
          sort_by: params[:sort_by],
          sort_direction: params[:sort_direction],
          page: params[:page],
          per_page: params[:per_page]
        ).call

        # render_success({
        #   followings: FollowingSerializer.serialize_collection(result[:followed_users], include_users: true),
        #   pagination: result[:pagination]
        # })
        render_success({
          followed_users: result[:followed_users].map { |user| UserSerializer.new(user).as_json },
          pagination: result[:pagination]
        })
      end

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
