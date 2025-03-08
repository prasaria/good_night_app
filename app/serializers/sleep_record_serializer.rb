# app/serializers/sleep_record_serializer.rb
class SleepRecordSerializer
  def initialize(sleep_record, options = {})
    @sleep_record = sleep_record
    @options = options
  end

  def as_json
    return {} unless @sleep_record

    {
      id: @sleep_record.id,
      user_id: @sleep_record.user_id,
      start_time: @sleep_record.start_time,
      end_time: @sleep_record.end_time,
      duration_minutes: @sleep_record.duration_minutes,
      completed: @sleep_record.completed?,
      created_at: @sleep_record.created_at,
      updated_at: @sleep_record.updated_at
    }.tap do |json|
      # Include user data if requested
      if @options[:include_user] && @sleep_record.user
        json[:user] = UserSerializer.new(@sleep_record.user).as_json
      end
    end
  end

  # Class method to handle bulk serialization to avoid N+1 queries
  def self.serialize_collection(sleep_records, options = {})
    # If we're including user data, we should preload the associations
    if options[:include_user]
      sleep_records = sleep_records.includes(:user) unless sleep_records.is_a?(Array)
    end

    sleep_records.map { |record| new(record, options).as_json }
  end
end
