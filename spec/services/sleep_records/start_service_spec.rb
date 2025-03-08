# spec/services/sleep_records/start_service_spec.rb
require 'rails_helper'

RSpec.describe SleepRecords::StartService do
  describe '#call' do
    let(:user) { create(:user) }

    context 'when successful' do
      # Check record creation
      it 'creates a new sleep record' do
        service = described_class.new(user: user)

        expect {
          service.call
        }.to change(SleepRecord, :count).by(1)
      end

      # Check record attributes
      it 'creates a record with correct attributes' do
        sleep_record = described_class.new(user: user).call

        aggregate_failures "verifying sleep record attributes" do
          expect(sleep_record).to be_persisted
          expect(sleep_record.user).to eq(user)
          expect(sleep_record.start_time).to be_present
          expect(sleep_record.end_time).to be_nil
          expect(sleep_record.duration_minutes).to be_nil
        end
      end

      it 'returns the created sleep record' do
        sleep_record = described_class.new(user: user).call
        expect(sleep_record).to be_a(SleepRecord)
      end

      it 'sets start time to current time by default' do
        freeze_time = Time.current
        allow(Time).to receive(:current).and_return(freeze_time)

        sleep_record = described_class.new(user: user).call
        expect(sleep_record.start_time).to eq(freeze_time)
      end

      it 'accepts custom start time' do
        custom_time = 1.hour.ago
        sleep_record = described_class.new(user: user, start_time: custom_time).call

        expect(sleep_record.start_time).to eq(custom_time)
      end
    end

    context 'when user already has an in-progress sleep record' do
      before do
        create(:sleep_record, user: user, start_time: 2.hours.ago, end_time: nil)
      end

      it 'raises UnprocessableEntityError' do
        service = described_class.new(user: user)

        expect {
          service.call
        }.to raise_error(Exceptions::UnprocessableEntityError, /already have an in-progress sleep record/i)
      end

      it 'does not create a new sleep record' do
        service = described_class.new(user: user)

        expect {
          begin
            service.call
          rescue Exceptions::UnprocessableEntityError
            # Expected error
          end
        }.not_to change(SleepRecord, :count)
      end
    end

    context 'when validation fails' do
      let(:invalid_start_time) { 1.hour.from_now }

      it 'raises UnprocessableEntityError for future start time' do
        service = described_class.new(user: user, start_time: invalid_start_time)

        expect {
          service.call
        }.to raise_error(Exceptions::UnprocessableEntityError, /cannot be in the future/i)
      end

      it 'does not create a new sleep record' do
        service = described_class.new(user: user, start_time: invalid_start_time)

        expect {
          begin
            service.call
          rescue Exceptions::UnprocessableEntityError
            # Expected error
          end
        }.not_to change(SleepRecord, :count)
      end
    end

    context 'when user is nil' do
      it 'raises BadRequestError' do
        service = described_class.new(user: nil)

        expect {
          service.call
        }.to raise_error(Exceptions::BadRequestError, /user is required/i)
      end
    end
  end
end
