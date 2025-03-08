# app/controllers/api/v1/sleep_records_controller.rb
module Api
  module V1
    class SleepRecordsController < BaseController
      # POST /api/v1/sleep_records/start
      def start
        validator = SleepRecordsValidator.new(params)
        validator.validate_start_action

        sleep_record = SleepRecords::StartService.new(
          user: validator.user,
          start_time: validator.start_time
        ).call

        render_success({
          sleep_record: SleepRecordSerializer.new(sleep_record).as_json
        }, :created)
      end

      # PATCH /api/v1/sleep_records/:id/end
      def end
        validator = SleepRecordsValidator.new(params)
        validator.validate_end_action(params[:id])

        sleep_record = SleepRecords::EndService.new(
          sleep_record: validator.sleep_record,
          end_time: validator.end_time
        ).call

        render_success({
          sleep_record: SleepRecordSerializer.new(sleep_record).as_json
        })
      end
    end
  end
end
