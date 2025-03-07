# app/services/sleep_records/start_service.rb
module SleepRecords
  class StartService
    attr_reader :user, :start_time

    def initialize(user:, start_time: nil)
      @user = user
      @start_time = start_time || Time.current
    end

    def call
      return ServiceResult.failure("User is required") if user.nil?

      if start_time > Time.current
        return ServiceResult.failure("Start time cannot be in the future")
      end

      # Check if user already has an in-progress sleep record
      if user.sleep_records.in_progress.exists?
        return ServiceResult.failure("You already have an in-progress sleep record")
      end

      # Create new sleep record
      sleep_record = user.sleep_records.new(
        start_time: start_time,
        end_time: nil,
        duration_minutes: nil
      )

      if sleep_record.save
        ServiceResult.success(sleep_record: sleep_record)
      else
        ServiceResult.failure(sleep_record.errors.full_messages)
      end
    end
  end
end
