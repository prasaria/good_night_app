# spec/serializers/sleep_record_serializer_spec.rb
require 'rails_helper'

RSpec.describe SleepRecordSerializer do
  describe '#as_json' do
    let(:user) { create(:user, name: 'John Doe') }
    let(:sleep_record) { create(:sleep_record,
      user: user,
      start_time: 8.hours.ago,
      end_time: 1.hour.ago,
      duration_minutes: 7 * 60
    )}

    it 'serializes basic sleep record attributes' do
      serialized = described_class.new(sleep_record).as_json

      expect(serialized).to include(
        id: sleep_record.id,
        user_id: user.id,
        start_time: sleep_record.start_time,
        end_time: sleep_record.end_time,
        duration_minutes: 7 * 60,
        completed: true
      )

      # Should not include user by default
      expect(serialized).not_to have_key(:user)
    end

    it 'includes user data when requested' do
      serialized = described_class.new(sleep_record, include_user: true).as_json

      expect(serialized).to have_key(:user)
      expect(serialized[:user]).to include(
        id: user.id,
        name: 'John Doe'
      )
    end

    it 'handles nil sleep record gracefully' do
      expect {
        serialized = described_class.new(nil).as_json
        expect(serialized).to eq({})
      }.not_to raise_error
    end
  end

  describe '.serialize_collection' do
    it 'efficiently serializes multiple sleep records' do
      user = create(:user)
      sleep_records = create_list(:sleep_record, 3, user: user)

      serialized = described_class.serialize_collection(sleep_records)

      expect(serialized.size).to eq(3)
      expect(serialized.first).to include(:id, :user_id)
    end

    it 'preloads user associations when including user data' do
      user = create(:user)
      sleep_records = create_list(:sleep_record, 3, user: user)

      # Test with a fresh collection to ensure we're testing the includes
      expect {
        described_class.serialize_collection(SleepRecord.where(id: sleep_records.map(&:id)), include_user: true)
      }.to make_database_queries(count: 2) # 1 for sleep records, 1 for users
    end
  end
end
