# spec/serializers/sleep_record_serializer_spec.rb
require 'rails_helper'

RSpec.describe SleepRecordSerializer do
  describe '#as_json' do
    subject(:sleep_record_as_json) { described_class.new(sleep_record).as_json }

    let(:user) { create(:user) }
    let(:start_time) { Time.zone.parse('2023-03-10 22:00:00') }
    let(:end_time) { Time.zone.parse('2023-03-11 06:00:00') }
    let(:sleep_record) do
      create(:sleep_record,
             user: user,
             start_time: start_time,
             end_time: end_time,
             duration_minutes: 480)
    end


    it 'serializes the basic attributes' do
      expect(sleep_record_as_json).to include(
        id: sleep_record.id,
        user_id: user.id,
        duration_minutes: 480
      )
    end

    it 'formats dates as ISO8601' do
      expect(sleep_record_as_json[:start_time]).to eq(start_time.iso8601)
      expect(sleep_record_as_json[:end_time]).to eq(end_time.iso8601)
      expect(sleep_record_as_json[:created_at]).to eq(sleep_record.created_at.iso8601)
      expect(sleep_record_as_json[:updated_at]).to eq(sleep_record.updated_at.iso8601)
    end

    context 'with a nil end_time' do
      subject(:sleep_record_nil_end_time) { described_class.new(in_progress_record).as_json }

      let(:in_progress_record) { create(:sleep_record, user: user, end_time: nil) }


      it 'handles nil end_time correctly' do
        expect(sleep_record_nil_end_time[:end_time]).to be_nil
        expect(sleep_record_nil_end_time[:duration_minutes]).to be_nil
      end
    end

    context 'with special characters or unusual data' do
      subject(:sleep_record_special_char) { described_class.new(record_with_special_data).as_json }

      let(:record_with_special_data) do
        create(:sleep_record,
               user: create(:user, name: "User with < & > characters"),
               duration_minutes: 0)
      end

      it 'handles special characters correctly' do
        # The serialization should not alter or escape the user_id
        expect(sleep_record_special_char[:user_id]).to eq(record_with_special_data.user_id)
      end

      it 'handles zero values correctly' do
        expect(sleep_record_special_char[:duration_minutes]).to eq(0)
      end
    end
  end

  describe '.render_collection' do
    subject(:sleep_record_collection) { described_class.render_collection(sleep_records) }

    let(:user) { create(:user) }
    let(:sleep_records) { create_list(:sleep_record, 3, user: user) }


    it 'serializes a collection of records' do
      expect(sleep_record_collection).to be_an(Array)
      expect(sleep_record_collection.size).to eq(3)
      expect(sleep_record_collection.first).to include(:id, :user_id, :start_time)
    end

    it 'produces the same output as individual serialization' do
      individual = sleep_records.map { |record| described_class.new(record).as_json }
      expect(sleep_record_collection).to eq(individual)
    end
  end
end
