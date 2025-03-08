# spec/validators/api/v1/sleep_records_validator_spec.rb
require 'rails_helper'

RSpec.describe Api::V1::SleepRecordsValidator do
  describe '#validate_start_action' do
    context 'with missing user_id' do
      let(:params) { {} }

      it 'fails validation' do
        validator = described_class.new(params)
        expect(validator.validate_start_action).to be false
      end

      it 'adds the correct error message' do
        validator = described_class.new(params)
        validator.validate_start_action
        expect(validator.error_message).to match(/user_id parameter is required/i)
      end

      it 'sets the correct error status' do
        validator = described_class.new(params)
        validator.validate_start_action
        expect(validator.error_status).to eq(:bad_request)
      end
    end

    context 'with non-existent user_id' do
      let(:params) { { user_id: 999999 } }

      it 'fails validation' do
        validator = described_class.new(params)
        expect(validator.validate_start_action).to be false
      end

      it 'adds the correct error message' do
        validator = described_class.new(params)
        validator.validate_start_action
        expect(validator.error_message).to match(/user not found/i)
      end

      it 'sets the correct error status' do
        validator = described_class.new(params)
        validator.validate_start_action
        expect(validator.error_status).to eq(:not_found)
      end
    end

    context 'with future start_time' do
      let(:user) { create(:user) }
      let(:params) { { user_id: user.id, start_time: 1.hour.from_now.iso8601 } }

      it 'fails validation' do
        validator = described_class.new(params)
        expect(validator.validate_start_action).to be false
      end

      it 'adds the correct error message' do
        validator = described_class.new(params)
        validator.validate_start_action
        expect(validator.error_message).to match(/cannot be in the future/i)
      end

      it 'sets the correct error status' do
        validator = described_class.new(params)
        validator.validate_start_action
        expect(validator.error_status).to eq(:unprocessable_entity)
      end
    end

    context 'with invalid start_time format' do
      let(:user) { create(:user) }
      let(:params) { { user_id: user.id, start_time: 'not-a-date' } }

      it 'fails validation' do
        validator = described_class.new(params)
        expect(validator.validate_start_action).to be false
      end

      it 'adds the correct error message' do
        validator = described_class.new(params)
        validator.validate_start_action
        expect(validator.error_message).to match(/invalid.*format/i)
      end

      it 'sets the correct error status' do
        validator = described_class.new(params)
        validator.validate_start_action
        expect(validator.error_status).to eq(:bad_request)
      end
    end

    context 'with valid params' do
      let(:user) { create(:user) }
      let(:valid_time) { 1.hour.ago }
      let(:params) { { user_id: user.id, start_time: valid_time.iso8601 } }

      it 'passes validation' do
        validator = described_class.new(params)
        expect(validator.validate_start_action).to be true
      end

      it 'has no error message' do
        validator = described_class.new(params)
        validator.validate_start_action
        expect(validator.error_message).to be_nil
      end

      it 'sets the user object' do
        validator = described_class.new(params)
        validator.validate_start_action
        expect(validator.user).to eq(user)
      end

      it 'sets the parsed start_time' do
        validator = described_class.new(params)
        validator.validate_start_action
        expect(validator.start_time).to be_within(1.second).of(valid_time)
      end
    end

    context 'with valid params but no start_time' do
      let(:user) { create(:user) }
      let(:params) { { user_id: user.id } }

      it 'passes validation' do
        validator = described_class.new(params)
        expect(validator.validate_start_action).to be true
      end

      it 'sets the user object' do
        validator = described_class.new(params)
        validator.validate_start_action
        expect(validator.user).to eq(user)
      end

      it 'has nil start_time' do
        validator = described_class.new(params)
        validator.validate_start_action
        expect(validator.start_time).to be_nil
      end
    end
  end

  describe '#error_status' do
    let(:validator) { described_class.new({}) }

    it 'maps user-related errors to not_found' do
      allow(validator).to receive(:error_message).and_return("User not found")
      expect(validator.error_status).to eq(:not_found)
    end

    it 'maps parameter errors to bad_request' do
      allow(validator).to receive(:error_message).and_return("user_id parameter is required")
      expect(validator.error_status).to eq(:bad_request)
    end

    it 'maps format errors to bad_request' do
      allow(validator).to receive(:error_message).and_return("Invalid start_time format")
      expect(validator.error_status).to eq(:bad_request)
    end

    it 'maps time constraint errors to unprocessable_entity' do
      allow(validator).to receive(:error_message).and_return("Start time cannot be in the future")
      expect(validator.error_status).to eq(:unprocessable_entity)
    end

    it 'maps in-progress errors to unprocessable_entity' do
      allow(validator).to receive(:error_message).and_return("You already have an in-progress sleep record")
      expect(validator.error_status).to eq(:unprocessable_entity)
    end

    it 'maps overlap errors to unprocessable_entity' do
      allow(validator).to receive(:error_message).and_return("Start time overlaps with another sleep record")
      expect(validator.error_status).to eq(:unprocessable_entity)
    end
  end
end
