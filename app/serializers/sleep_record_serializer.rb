# app/serializers/sleep_record_serializer.rb
class SleepRecordSerializer < ApplicationSerializer
  def as_json(*)
    {
      id: @resource.id,
      user_id: @resource.user_id,
      start_time: @resource.start_time.iso8601,
      end_time: @resource.end_time&.iso8601,
      duration_minutes: @resource.duration_minutes,
      created_at: @resource.created_at.iso8601,
      updated_at: @resource.updated_at.iso8601
    }
  end
end
