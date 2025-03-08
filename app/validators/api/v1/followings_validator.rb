# app/validators/api/v1/followings_validator.rb
module Api
  module V1
    class FollowingsValidator
      attr_reader :params, :follower, :followed

      def initialize(params)
        @params = params
        @follower = nil
        @followed = nil
      end

      def validate_create_action
        validate_follower_id_presence
        validate_followed_id_presence
        validate_follower_exists
        validate_followed_exists
        validate_not_self_following
        validate_not_already_following
        true
      end

      private

      def validate_follower_id_presence
        unless params[:follower_id].present?
          raise Exceptions::BadRequestError, "follower_id parameter is required"
        end
      end

      def validate_followed_id_presence
        unless params[:followed_id].present?
          raise Exceptions::BadRequestError, "followed_id parameter is required"
        end
      end

      def validate_follower_exists
        begin
          @follower = User.find(params[:follower_id])
        rescue ActiveRecord::RecordNotFound
          raise Exceptions::NotFoundError, "Follower user not found"
        end
      end

      def validate_followed_exists
        begin
          @followed = User.find(params[:followed_id])
        rescue ActiveRecord::RecordNotFound
          raise Exceptions::NotFoundError, "Followed user not found"
        end
      end

      def validate_not_self_following
        if @follower&.id == @followed&.id
          raise Exceptions::UnprocessableEntityError, "You cannot follow yourself"
        end
      end

      def validate_not_already_following
        if @follower && @followed && Following.exists?(follower: @follower, followed: @followed)
          raise Exceptions::UnprocessableEntityError, "You are already following this user"
        end
      end
    end
  end
end
