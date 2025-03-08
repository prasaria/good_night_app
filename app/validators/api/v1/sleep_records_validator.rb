# app/validators/api/v1/sleep_records_validator.rb
module Api
  module V1
    class SleepRecordsValidator
      attr_reader :params, :errors, :user, :start_time, :sleep_record, :end_time

      def initialize(params)
        @params = params
        @errors = []
        @user = nil
        @start_time = nil
        @sleep_record = nil
        @end_time = nil
      end

      def validate_start_action
        validate_user_id_presence
        return false if @errors.any?

        validate_user_exists
        return false if @errors.any?

        validate_start_time
        @errors.empty?
      end

      def validate_end_action(sleep_record_id)
        validate_user_id_presence
        return false if @errors.any?

        validate_user_exists
        return false if @errors.any?

        validate_sleep_record_exists(sleep_record_id)
        return false if @errors.any?

        validate_user_owns_sleep_record(@sleep_record)
        return false if @errors.any?

        validate_sleep_record_in_progress
        return false if @errors.any?

        validate_end_time
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
        when /not authorized/i
          :forbidden
        when /already have an in-progress/i, /cannot be in the future/i, /overlaps/i,
             /already completed/i, /must be after/i
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

      def validate_sleep_record_exists(sleep_record_id)
        begin
          @sleep_record = SleepRecord.find(sleep_record_id)
        rescue ActiveRecord::RecordNotFound
          @errors << "Sleep record not found"
        end
      end

      def validate_user_owns_sleep_record(sleep_record)
        return unless sleep_record && @user

        unless sleep_record.user_id == @user.id
          @errors << "You are not authorized to update this sleep record"
        end
      end

      def validate_sleep_record_in_progress
        return unless @sleep_record

        if @sleep_record.end_time.present?
          @errors << "Sleep record is already completed"
        end
      end

      def validate_start_time
        return unless params[:start_time].present?

        begin
          if valid_iso8601_format?(params[:start_time])
            @start_time = Time.zone.parse(params[:start_time])
            @errors << "Start time cannot be in the future" if @start_time > Time.current
          else
            @errors << "Invalid start_time format"
          end
        rescue ArgumentError
          @errors << "Invalid start_time format"
        end
      end

      def validate_end_time
        return unless params[:end_time].present?

        begin
          if valid_iso8601_format?(params[:end_time])
            @end_time = Time.zone.parse(params[:end_time])
            @errors << "End time cannot be in the future" if @end_time > Time.current
            @errors << "End time must be after start time" if @sleep_record && @end_time <= @sleep_record.start_time
          else
            @errors << "Invalid end_time format"
          end
        rescue ArgumentError
          @errors << "Invalid end_time format"
        end
      end

      # Validates if string follows ISO 8601 format (YYYY-MM-DDThh:mm:ss[.sss][Z|±hh:mm])
      def valid_iso8601_format?(string)
        # Basic ISO 8601 regex pattern
        iso8601_pattern = /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:?\d{2})?\z/

        # Check if string matches the pattern
        string.match?(iso8601_pattern)
      end
    end
  end
end
