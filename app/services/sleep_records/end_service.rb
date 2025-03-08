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
      raise Exceptions::BadRequestError, "Sleep record is required" if sleep_record.nil?

      # Check if record is already completed
      if sleep_record.end_time.present?
        raise Exceptions::UnprocessableEntityError, "Sleep record is already completed"
      end

      # Validate end time is after start time
      if end_time <= sleep_record.start_time
        raise Exceptions::UnprocessableEntityError, "End time must be after start time"
      end

      # Validate end time is not in the future
      if end_time > Time.current
        raise Exceptions::UnprocessableEntityError, "End time cannot be in the future"
      end

      # Update the sleep record
      sleep_record.end_time = end_time

      # Use the calculator to determine duration
      sleep_record.duration_minutes = DurationCalculator.calculate_minutes(
        sleep_record.start_time,
        sleep_record.end_time
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
