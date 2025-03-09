# app/controllers/api/v1/sleep_records_controller.rb
module Api
  module V1
    class SleepRecordsController < BaseController
      include CacheHelper

      # GET /api/v1/sleep_records
      def index
        validator = SleepRecordsValidator.new(params)
        validator.validate_index_action

        # Wrap the caching in a begin/rescue block
        begin
          # Only try to use cache if caching is enabled
          if Rails.application.config.action_controller.perform_caching
            cache_key = collection_cache_key("sleep_record", validator.user.id, params)
            Rails.logger.info "Cache key generated: #{cache_key}"

            start_time = Time.zone.now
            result = fetch_cached_collection(cache_key) do
              Rails.logger.info "Cache MISS for Sleep Records #Index - retrieving from database"
              retrieve_sleep_records(validator)
            end
            duration = Time.zone.now - start_time
            Rails.logger.info "Data retrieval completed in #{duration} seconds"
          else
            # Skip caching if disabled
            Rails.logger.info "Caching disabled, retrieving directly from database"
            result = retrieve_sleep_records(validator)
          end

          render_success({
            sleep_records: result[:records].map { |record| SleepRecordSerializer.new(record).as_json },
            pagination: result[:pagination]
          })
        rescue => e
          # Log the error
          Rails.logger.error "Error in SleepRecordsController#index: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")

          # Fall back to non-cached version
          result = retrieve_sleep_records(validator)

          render_success({
            sleep_records: result[:records].map { |record| SleepRecordSerializer.new(record).as_json },
            pagination: result[:pagination]
          })
        end
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

      private

      # Extract the service call to a separate method for reuse
      def retrieve_sleep_records(validator)
        SleepRecords::RetrievalService.new(
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
      end
    end
  end
end
