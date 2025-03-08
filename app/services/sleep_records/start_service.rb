# app/services/sleep_records/start_service.rb
module SleepRecords
  class StartService
    attr_reader :user, :start_time

    def initialize(user:, start_time: nil)
      @user = user
      @start_time = start_time || Time.current
    end

    def call
      raise Exceptions::BadRequestError, "User is required" if user.nil?

      if start_time > Time.current
        raise Exceptions::UnprocessableEntityError, "Start time cannot be in the future"
      end

      # Check if user already has an in-progress sleep record
      if user.sleep_records.in_progress.exists?
        raise Exceptions::UnprocessableEntityError, "You already have an in-progress sleep record"
      end

      # Create new sleep record
      sleep_record = user.sleep_records.new(
        start_time: start_time,
        end_time: nil,
        duration_minutes: nil
      )

      unless sleep_record.save
        # Convert ActiveRecord errors to a single exception
        error_message = sleep_record.errors.full_messages.join(", ")
        raise Exceptions::UnprocessableEntityError, error_message
      end

      # Return the sleep record directly
      sleep_record
    end
  end
end
