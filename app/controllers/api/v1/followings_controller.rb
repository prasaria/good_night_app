# app/controllers/api/v1/followings_controller.rb
module Api
  module V1
    class FollowingsController < BaseController
      include CacheHelper

      # GET /api/v1/followings
      def index
        validator = FollowingsValidator.new(params)
        validator.validate_index_action

        # Wrap the caching in a begin / rescue block
        begin
          # Only try to use cache if caching is enabled
          if Rails.application.config.action_controller.perform_caching
            cache_key = collection_cache_key("following", validator.user.id, params)
            Rails.logger.info "Cache key generated: #{cache_key}"

            start_time = Time.zone.now
            result = fetch_cached_collection(cache_key) do
              Rails.logger.info "Cache MISS for Followings #Index - retrieving from database"
              retrieve_followings(validator)
            end
            duration = Time.zone.now - start_time
            Rails.logger.info "Data retrieval completed in #{duration} seconds"
          else
            # Skip caching if disabled
            Rails.logger.info "Caching disabled, retrieving directly from database"
            result = retrieve_followings(validator)
          end

          render_success({
            followed_users: result[:followed_users].map { |user| UserSerializer.new(user).as_json },
            pagination: result[:pagination]
          })
        rescue => e
          # Log the error
          Rails.logger.error "Error in FollowingsController#index: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")

          # Fall back to non-cached version
          result = retrieve_followings(validator)

          render_success({
            followed_users: result[:followed_users].map { |user| UserSerializer.new(user).as_json },
            pagination: result[:pagination]
          })
        end
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

      private

      # Extract the service call to a separate method for reuse
      def retrieve_followings(validator)
        Followings::ListService.new(
          user: validator.user,
          sort_by: params[:sort_by],
          sort_direction: params[:sort_direction],
          page: params[:page],
          per_page: params[:per_page]
        ).call
      end
    end
  end
end
