# app/controllers/api/v1/sleep_records_controller.rb
module Api
  module V1
    class SleepRecordsController < BaseController
      # POST /api/v1/sleep_records/start
      def start
        # Validate required parameters first
        return render_error("user_id parameter is required", :bad_request) unless params[:user_id].present?

        # Find the user
        begin
          user = User.find(params[:user_id])
        rescue ActiveRecord::RecordNotFound
          return render_error("User not found", :not_found)
        end

        # Parse start_time if provided
        start_time = params[:start_time].present? ? Time.zone.parse(params[:start_time]) : nil

        # Use the service to create a sleep record
        result = SleepRecords::StartService.new(
          user: user,
          start_time: start_time
        ).call

        if result.success?
          render_success({ sleep_record: serialize_sleep_record(result.sleep_record) }, :created)
        else
          # For service-specific errors, map to appropriate status codes
          status_code = determine_error_status_code(result.errors.first)
          render_error(result.errors, status_code)
        end
      end

      private

      def serialize_sleep_record(record)
        {
          id: record.id,
          user_id: record.user_id,
          start_time: record.start_time.iso8601,
          end_time: record.end_time&.iso8601,
          duration_minutes: record.duration_minutes,
          created_at: record.created_at.iso8601,
          updated_at: record.updated_at.iso8601
        }
      end

      def determine_error_status_code(error_message)
        case error_message
        when /already have an in-progress/i, /cannot be in the future/i, /overlaps/i
          :unprocessable_entity
        else
          :bad_request
        end
      end

      def render_error(errors, status = :bad_request)
        error_message = Array(errors).first

        render json: {
          status: "error",
          message: status.to_s.humanize,
          details: error_message
        }, status: status
      end
    end
  end
end
