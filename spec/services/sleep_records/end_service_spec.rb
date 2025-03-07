# spec/services/sleep_records/end_service_spec.rb
require 'rails_helper'

RSpec.describe SleepRecords::EndService do
  describe '#call' do
    let(:user) { create(:user) }
    let(:end_time) { Time.current }

    context 'when sleep record exists and is in progress' do
      let!(:sleep_record) { create(:sleep_record, user: user, start_time: 8.hours.ago, end_time: nil) }

      it 'updates the sleep record with end time' do
        service = described_class.new(sleep_record: sleep_record, end_time: end_time)
        result = service.call

        expect(result.success?).to be true
        expect(sleep_record.reload.end_time).to be_within(1.second).of(end_time)
      end

      it 'calculates the duration in minutes' do
        service = described_class.new(sleep_record: sleep_record, end_time: end_time)
        _result = service.call

        # Expect around 8 hours = 480 minutes
        expected_minutes = (end_time - sleep_record.start_time) / 60
        expect(sleep_record.reload.duration_minutes).to be_within(1).of(expected_minutes)
      end

      it 'returns the updated sleep record' do
        service = described_class.new(sleep_record: sleep_record, end_time: end_time)
        result = service.call

        expect(result.sleep_record).to eq(sleep_record)
      end

      it 'uses current time by default' do
        freeze_time = Time.current
        allow(Time).to receive(:current).and_return(freeze_time)

        service = described_class.new(sleep_record: sleep_record)
        service.call

        expect(sleep_record.reload.end_time).to eq(freeze_time)
      end
    end

    context 'when end time is before start time' do
      let(:sleep_record) { create(:sleep_record, user: user, start_time: 1.hour.ago, end_time: nil) }
      let(:invalid_end_time) { sleep_record.start_time - 1.hour }

      it 'returns an error' do
        service = described_class.new(sleep_record: sleep_record, end_time: invalid_end_time)
        result = service.call

        expect(result.success?).to be false
        expect(result.errors).to include("End time must be after start time")
      end

      it 'does not update the sleep record' do
        service = described_class.new(sleep_record: sleep_record, end_time: invalid_end_time)
        service.call

        expect(sleep_record.reload.end_time).to be_nil
      end
    end

    context 'when end time is in the future' do
      let(:sleep_record) { create(:sleep_record, user: user, start_time: 1.hour.ago, end_time: nil) }
      let(:future_end_time) { 1.hour.from_now }

      it 'returns an error' do
        service = described_class.new(sleep_record: sleep_record, end_time: future_end_time)
        result = service.call

        expect(result.success?).to be false
        expect(result.errors).to include("End time cannot be in the future")
      end
    end

    context 'when sleep record is already completed' do
      let(:sleep_record) { create(:sleep_record, user: user, start_time: 9.hours.ago, end_time: 1.hour.ago) }

      it 'returns an error' do
        service = described_class.new(sleep_record: sleep_record)
        result = service.call

        expect(result.success?).to be false
        expect(result.errors).to include("Sleep record is already completed")
      end

      it 'does not update the sleep record' do
        original_end_time = sleep_record.end_time

        service = described_class.new(sleep_record: sleep_record)
        service.call

        expect(sleep_record.reload.end_time).to eq(original_end_time)
      end
    end

    context 'when sleep record is nil' do
      it 'returns an error' do
        service = described_class.new(sleep_record: nil)
        result = service.call

        expect(result.success?).to be false
        expect(result.errors).to include("Sleep record is required")
      end
    end

    context 'when sleep record does not belong to user' do
      let(:another_user) { create(:user) }
      let(:sleep_record) { create(:sleep_record, user: user, start_time: 8.hours.ago, end_time: nil) }

      it 'still updates the record regardless of user' do
        service = described_class.new(sleep_record: sleep_record, user: another_user)
        result = service.call

        expect(result.success?).to be true
        expect(sleep_record.reload.end_time).to be_present
      end
    end
  end
end
