# app/services/sleep_records/end_service.rb
module SleepRecords
  class EndService
    attr_reader :sleep_record, :end_time, :user

    def initialize(sleep_record:, end_time: nil, user: nil)
      @sleep_record = sleep_record
      @end_time = end_time || Time.current
      @user = user
    end

    def call
      return ServiceResult.failure("Sleep record is required") if sleep_record.nil?

      # Check if record is already completed
      if sleep_record.end_time.present?
        return ServiceResult.failure("Sleep record is already completed")
      end

      # Validate end time is after start time
      if end_time <= sleep_record.start_time
        return ServiceResult.failure("End time must be after start time")
      end

      # Validate end time is not in the future
      if end_time > Time.current
        return ServiceResult.failure("End time cannot be in the future")
      end

      # Update the sleep record
      sleep_record.end_time = end_time

      # Calculate duration in minutes
      sleep_record.duration_minutes = ((end_time - sleep_record.start_time) / 60).to_i

      if sleep_record.save
        ServiceResult.success(sleep_record: sleep_record)
      else
        ServiceResult.failure(sleep_record.errors.full_messages)
      end
    end
  end
end
