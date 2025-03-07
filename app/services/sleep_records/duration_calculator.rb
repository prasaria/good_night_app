# app/services/sleep_records/duration_calculator.rb
module SleepRecords
  class DurationCalculator
    class << self
      # Calculate duration in minutes between two times
      def calculate_minutes(start_time, end_time)
        # Return nil for invalid inputs
        return nil if start_time.nil? || end_time.nil?
        return nil if end_time <= start_time

        # Calculate duration in minutes
        ((end_time - start_time) / 60.0).round
      end

      # Calculate duration for a sleep record
      def for_sleep_record(sleep_record, use_current_time: false)
        return nil if sleep_record.nil?

        start_time = sleep_record.start_time
        end_time = sleep_record.end_time

        # If record is in progress but current time requested
        if end_time.nil? && use_current_time
          end_time = Time.current
        end

        calculate_minutes(start_time, end_time)
      end
    end
  end
end
