# spec/services/sleep_records/end_service_spec.rb
require 'rails_helper'

RSpec.describe SleepRecords::EndService do
  describe '#call' do
    let(:user) { create(:user) }
    let(:end_time) { Time.current }

    context 'when sleep record exists and is in progress' do
      let!(:sleep_record) { create(:sleep_record, user: user, start_time: 8.hours.ago, end_time: nil) }

      it 'updates the sleep record with end time' do
        updated_record = described_class.new(sleep_record: sleep_record, end_time: end_time).call

        expect(updated_record.end_time).to be_within(1.second).of(end_time)
        expect(sleep_record.reload.end_time).to be_within(1.second).of(end_time)
      end

      it 'calculates the duration in minutes' do
        updated_record = described_class.new(sleep_record: sleep_record, end_time: end_time).call

        # Expect around 8 hours = 480 minutes
        expected_minutes = (end_time - sleep_record.start_time) / 60
        expect(updated_record.duration_minutes).to be_within(1).of(expected_minutes)
        expect(sleep_record.reload.duration_minutes).to be_within(1).of(expected_minutes)
      end

      it 'returns the updated sleep record' do
        updated_record = described_class.new(sleep_record: sleep_record, end_time: end_time).call

        expect(updated_record).to eq(sleep_record)
        expect(updated_record.id).to eq(sleep_record.id)
      end

      it 'uses current time by default' do
        freeze_time = Time.current
        allow(Time).to receive(:current).and_return(freeze_time)

        updated_record = described_class.new(sleep_record: sleep_record).call

        expect(updated_record.end_time).to eq(freeze_time)
        expect(sleep_record.reload.end_time).to eq(freeze_time)
      end
    end

    context 'when end time is before start time' do
      let(:sleep_record) { create(:sleep_record, user: user, start_time: 1.hour.ago, end_time: nil) }
      let(:invalid_end_time) { sleep_record.start_time - 1.hour }

      it 'raises UnprocessableEntityError' do
        service = described_class.new(sleep_record: sleep_record, end_time: invalid_end_time)

        expect {
          service.call
        }.to raise_error(Exceptions::UnprocessableEntityError, /must be after start time/i)
      end

      it 'does not update the sleep record' do
        service = described_class.new(sleep_record: sleep_record, end_time: invalid_end_time)

        expect {
          begin
            service.call
          rescue Exceptions::UnprocessableEntityError
            # Expected error
          end
        }.not_to change { sleep_record.reload.end_time }.from(nil)
      end
    end

    context 'when end time is in the future' do
      let(:sleep_record) { create(:sleep_record, user: user, start_time: 1.hour.ago, end_time: nil) }
      let(:future_end_time) { 1.hour.from_now }

      it 'raises UnprocessableEntityError' do
        service = described_class.new(sleep_record: sleep_record, end_time: future_end_time)

        expect {
          service.call
        }.to raise_error(Exceptions::UnprocessableEntityError, /cannot be in the future/i)
      end
    end

    context 'when sleep record is already completed' do
      let(:sleep_record) { create(:sleep_record, user: user, start_time: 9.hours.ago, end_time: 1.hour.ago) }

      it 'raises UnprocessableEntityError' do
        service = described_class.new(sleep_record: sleep_record)

        expect {
          service.call
        }.to raise_error(Exceptions::UnprocessableEntityError, /already completed/i)
      end

      it 'does not update the sleep record' do
        original_end_time = sleep_record.end_time
        service = described_class.new(sleep_record: sleep_record)

        expect {
          begin
            service.call
          rescue Exceptions::UnprocessableEntityError
            # Expected error
          end
        }.not_to change { sleep_record.reload.end_time }.from(original_end_time)
      end
    end

    context 'when sleep record is nil' do
      it 'raises BadRequestError' do
        service = described_class.new(sleep_record: nil)

        expect {
          service.call
        }.to raise_error(Exceptions::BadRequestError, /sleep record is required/i)
      end
    end

    context 'when sleep record does not belong to user' do
      let(:another_user) { create(:user) }
      let(:sleep_record) { create(:sleep_record, user: user, start_time: 8.hours.ago, end_time: nil) }

      it 'still updates the record regardless of user' do
        updated_record = described_class.new(sleep_record: sleep_record, user: another_user).call

        expect(updated_record.end_time).to be_present
        expect(sleep_record.reload.end_time).to be_present
      end
    end
  end
end
