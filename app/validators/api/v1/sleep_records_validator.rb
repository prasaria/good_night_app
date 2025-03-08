# app/validators/api/v1/sleep_records_validator.rb
module Api
  module V1
    class SleepRecordsValidator
      attr_reader :params, :user, :start_time, :sleep_record, :end_time

      def initialize(params)
        @params = params
        @user = nil
        @start_time = nil
        @sleep_record = nil
        @end_time = nil
      end

      def validate_start_action
        validate_user_id_presence
        validate_user_exists
        validate_start_time
        true
      end

      def validate_end_action(sleep_record_id)
        validate_user_id_presence
        validate_user_exists
        validate_sleep_record_exists(sleep_record_id)
        validate_user_owns_sleep_record(@sleep_record)
        validate_sleep_record_in_progress
        validate_end_time
        true
      end

      private

      def validate_user_id_presence
        unless params[:user_id].present?
          raise Exceptions::BadRequestError, "user_id parameter is required"
        end
      end

      def validate_user_exists
        begin
          @user = User.find(params[:user_id])
        rescue ActiveRecord::RecordNotFound
          raise Exceptions::NotFoundError, "User not found"
        end
      end

      def validate_sleep_record_exists(sleep_record_id)
        begin
          @sleep_record = SleepRecord.find(sleep_record_id)
        rescue ActiveRecord::RecordNotFound
          raise Exceptions::NotFoundError, "Sleep record not found"
        end
      end

      def validate_user_owns_sleep_record(sleep_record)
        return unless sleep_record && @user

        unless sleep_record.user_id == @user.id
          raise Exceptions::ForbiddenError, "You are not authorized to update this sleep record"
        end
      end

      def validate_sleep_record_in_progress
        return unless @sleep_record

        if @sleep_record.end_time.present?
          raise Exceptions::UnprocessableEntityError, "Sleep record is already completed"
        end
      end

      def validate_start_time
        return unless params[:start_time].present?

        begin
          if valid_iso8601_format?(params[:start_time])
            @start_time = Time.zone.parse(params[:start_time])
            if @start_time > Time.current
              raise Exceptions::UnprocessableEntityError, "Start time cannot be in the future"
            end
          else
            raise Exceptions::BadRequestError, "Invalid start_time format"
          end
        rescue ArgumentError
          raise Exceptions::BadRequestError, "Invalid start_time format"
        end
      end

      def validate_end_time
        return unless params[:end_time].present?

        begin
          if valid_iso8601_format?(params[:end_time])
            @end_time = Time.zone.parse(params[:end_time])

            if @end_time > Time.current
              raise Exceptions::UnprocessableEntityError, "End time cannot be in the future"
            end

            if @sleep_record && @end_time <= @sleep_record.start_time
              raise Exceptions::UnprocessableEntityError, "End time must be after start time"
            end
          else
            raise Exceptions::BadRequestError, "Invalid end_time format"
          end
        rescue ArgumentError
          raise Exceptions::BadRequestError, "Invalid end_time format"
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
