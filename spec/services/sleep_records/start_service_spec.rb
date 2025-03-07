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

      # Check success status
      it 'returns a successful result' do
        result = described_class.new(user: user).call
        expect(result.success?).to be true
      end

      # Check record attributes
      it 'creates a record with correct attributes' do
        result = described_class.new(user: user).call
        sleep_record = result.sleep_record

        aggregate_failures "verifying sleep record attributes" do
          expect(sleep_record).to be_persisted
          expect(sleep_record.user).to eq(user)
          expect(sleep_record.start_time).to be_present
          expect(sleep_record.end_time).to be_nil
          expect(sleep_record.duration_minutes).to be_nil
        end
      end

      it 'returns the created sleep record' do
        result = described_class.new(user: user).call
        expect(result.sleep_record).to be_a(SleepRecord)
      end

      it 'sets start time to current time by default' do
        freeze_time = Time.current
        allow(Time).to receive(:current).and_return(freeze_time)

        result = described_class.new(user: user).call
        expect(result.sleep_record.start_time).to eq(freeze_time)
      end

      it 'accepts custom start time' do
        custom_time = 1.hour.ago
        result = described_class.new(user: user, start_time: custom_time).call

        expect(result.sleep_record.start_time).to eq(custom_time)
      end
    end

    context 'when user already has an in-progress sleep record' do
      before do
        create(:sleep_record, user: user, start_time: 2.hours.ago, end_time: nil)
      end

      it 'returns an error' do
        service = described_class.new(user: user)
        result = service.call

        expect(result.success?).to be false
        expect(result.errors).to include("You already have an in-progress sleep record")
      end

      it 'does not create a new sleep record' do
        service = described_class.new(user: user)

        expect {
          service.call
        }.not_to change(SleepRecord, :count)
      end
    end

    context 'when validation fails' do
      let(:invalid_start_time) { 1.hour.from_now }

      it 'returns validation errors' do
        service = described_class.new(user: user, start_time: invalid_start_time)
        result = service.call

        expect(result.success?).to be false
        expect(result.errors).to include("Start time cannot be in the future")
      end

      it 'does not create a new sleep record' do
        service = described_class.new(user: user, start_time: invalid_start_time)

        expect {
          service.call
        }.not_to change(SleepRecord, :count)
      end
    end

    context 'when user is nil' do
      it 'returns an error' do
        service = described_class.new(user: nil)
        result = service.call

        expect(result.success?).to be false
        expect(result.errors).to include("User is required")
      end
    end
  end
end
