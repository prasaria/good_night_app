# app/controllers/api/v1/followings_sleep_records_controller.rb
module Api
  module V1
    class FollowingsSleepRecordsController < BaseController
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

      result = SleepRecords::FollowingRetrievalService.new(
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

      render_success({
        sleep_records: result[:records].map { |record| SleepRecordSerializer.new(record, include_user: true).as_json },
        pagination: result[:pagination]
      })
    end
    end
  end
end
