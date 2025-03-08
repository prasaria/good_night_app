# app/controllers/api/v1/sleep_records_controller.rb
module Api
  module V1
    class SleepRecordsController < BaseController
      # POST /api/v1/sleep_records/start
      def start
        validator = SleepRecordsValidator.new(params)

        unless validator.validate_start_action
          return render_error(validator.error_message, validator.error_status)
        end

        result = SleepRecords::StartService.new(
          user: validator.user,
          start_time: validator.start_time
        ).call

        if result.success?
          render_success({
            sleep_record: SleepRecordSerializer.new(result.sleep_record).as_json
          }, :created)
        else
          status_code = determine_service_error_status_code(result.errors.first)
          render_error(result.errors, status_code)
        end
      end

      # PATCH /api/v1/sleep_records/:id/end
      def end
        validator = SleepRecordsValidator.new(params)

        unless validator.validate_end_action(params[:id])
          return render_error(validator.error_message, validator.error_status)
        end

        result = SleepRecords::EndService.new(
          sleep_record: validator.sleep_record,
          end_time: validator.end_time
        ).call

        if result.success?
          render_success({ sleep_record: SleepRecordSerializer.new(result.sleep_record).as_json })
        else
          status_code = determine_service_error_status_code(result.errors.first)
          render_error(result.errors, status_code)
        end
      end

      private

      def determine_service_error_status_code(error_message)
        case error_message
        when /already have an in-progress/i, /cannot be in the future/i, /overlaps/i
          :unprocessable_entity
        else
          :bad_request
        end
      end
    end
  end
end
