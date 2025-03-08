# app/validators/api/v1/sleep_records_validator.rb
module Api
  module V1
    class SleepRecordsValidator
      attr_reader :params, :errors, :user, :start_time

      def initialize(params)
        @params = params
        @errors = []
        @user = nil
      end

      def validate_start_action
        validate_user_id_presence
        validate_user_exists if @errors.empty?
        validate_start_time if @errors.empty?

        @errors.empty?
      end

      def error_message
        @errors.first
      end

      def error_status
        case error_message
        when /parameter is required/i, /invalid format/i
          :bad_request
        when /not found/i
          :not_found
        when /already have an in-progress/i, /cannot be in the future/i, /overlaps/i
          :unprocessable_entity
        else
          :bad_request
        end
      end

      private

      def validate_user_id_presence
        @errors << "user_id parameter is required" unless params[:user_id].present?
      end

      def validate_user_exists
        begin
          @user = User.find(params[:user_id])
        rescue ActiveRecord::RecordNotFound
          @errors << "User not found"
        end
      end

      def validate_start_time
        return unless params[:start_time].present?

        begin
          @start_time = Time.zone.parse(params[:start_time])
          @errors << "Start time cannot be in the future" if @start_time > Time.current
        rescue ArgumentError
          @errors << "Invalid start_time format"
        end
      end
    end
  end
end
