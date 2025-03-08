# app/validators/api/v1/followings_sleep_records_validator.rb
module Api
  module V1
    class FollowingsSleepRecordsValidator
      attr_reader :params, :user, :start_date, :end_date

      def initialize(params)
        @params = params
        @user = nil
        @start_date = nil
        @end_date = nil
      end

      def validate_index_action
        validate_user_id_presence
        validate_user_exists
        validate_date_range if date_range_params_present?
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

      def date_range_params_present?
        params[:start_date].present? || params[:end_date].present?
      end

      def validate_date_range
        if params[:start_date].present?
          begin
            if valid_iso8601_format?(params[:start_date])
              @start_date = Time.zone.parse(params[:start_date])
            else
              raise Exceptions::BadRequestError, "Invalid start_date format"
            end
          rescue ArgumentError
            raise Exceptions::BadRequestError, "Invalid start_date format"
          end
        end

        if params[:end_date].present?
          begin
            if valid_iso8601_format?(params[:end_date])
              @end_date = Time.zone.parse(params[:end_date])
            else
              raise Exceptions::BadRequestError, "Invalid end_date format"
            end
          rescue ArgumentError
            raise Exceptions::BadRequestError, "Invalid end_date format"
          end
        end

        # If both dates are provided, verify start_date is before end_date
        if @start_date.present? && @end_date.present? && @start_date > @end_date
          raise Exceptions::BadRequestError, "start_date must be before end_date"
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
