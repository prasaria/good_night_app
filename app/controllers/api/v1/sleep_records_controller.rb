# app/controllers/api/v1/sleep_records_controller.rb
module Api
  module V1
    class SleepRecordsController < BaseController
      # GET /api/v1/sleep_records
      def index
        validator = SleepRecordsValidator.new(params)
        validator.validate_index_action

        result = SleepRecords::RetrievalService.new(
          user: validator.user,
          start_date: validator.start_date,
          end_date: validator.end_date,
          from_last_week: params[:from_last_week].present?,
          completed_only: params[:completed_only].present?,
          in_progress_only: params[:in_progress_only].present?,
          sort_by: params[:sort_by],
          sort_direction: params[:sort_direction],
          page: params[:page],
          per_page: params[:per_page],
          limit: params[:limit]
        ).call

        render_success({
          sleep_records: result[:records].map { |record| SleepRecordSerializer.new(record).as_json },
          pagination: result[:pagination]
        })
      end

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
