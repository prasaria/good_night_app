# app/controllers/api/v1/followings_sleep_records_controller.rb
module Api
  module V1
    class FollowingsSleepRecordsController < BaseController
      include CacheHelper

      # GET /api/v1/followings/sleep_records
      def index
        validator = FollowingsSleepRecordsValidator.new(params)
        validator.validate_index_action

        # Properly format followed_user_ids as an array
        followed_user_ids = if params[:followed_user_ids].is_a?(Array)
                              params[:followed_user_ids]
        elsif params[:followed_user_ids].present?
                              [ params[:followed_user_ids] ].flatten
        else
                              nil
        end

        # Wrap the caching in a begin / rescue block
        begin
          # Only try to use cache if caching is enabled
          if Rails.application.config.action_controller.perform_caching
            cache_key = collection_cache_key("sleep_record_following", validator.user.id, params)
            Rails.logger.info "Cache key generated: #{cache_key}"

            start_time = Time.zone.now
            result = fetch_cached_collection(cache_key) do
              Rails.logger.info "Cache MISS for Followings Sleep Record #Index - retrieving from database"
              retrieve_following_sleep_records(validator, params, followed_user_ids)
            end
            duration = Time.zone.now - start_time
            Rails.logger.info "Data retrieval completed in #{duration} seconds"
          else
            # Skip caching if disabled
            Rails.logger.info "Caching disabled, retrieving directly from database"
            result = retrieve_following_sleep_records(validator, params, followed_user_ids)
          end

          render_success({
            sleep_records: result[:records].map { |record| SleepRecordSerializer.new(record, include_user: true).as_json },
            pagination: result[:pagination]
          })
        rescue => e
          # Log the error
          Rails.logger.error "Error in FollowingsSleepRecordsController#index: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")

          # Fall back to non-cached version
          result = retrieve_following_sleep_records(validator, params, followed_user_ids)

          render_success({
            sleep_records: result[:records].map { |record| SleepRecordSerializer.new(record, include_user: true).as_json },
            pagination: result[:pagination]
          })
        end
      end

      private

      # Extract the service call to a separate method for reuse
      def retrieve_following_sleep_records(validator, params, followed_user_ids)
        SleepRecords::FollowingRetrievalService.new(
          user: validator.user,
          start_date: validator.start_date,
          end_date: validator.end_date,
          from_last_week: params[:from_last_week].present?,
          completed_only: params[:completed_only].present?,
          in_progress_only: params[:in_progress_only].present?,
          followed_user_ids: followed_user_ids,
          sort_by: params[:sort_by],
          sort_direction: params[:sort_direction],
          page: params[:page],
          per_page: params[:per_page],
          limit: params[:limit]
        ).call
      end
    end
  end
end
