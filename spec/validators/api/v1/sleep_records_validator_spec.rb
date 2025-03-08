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

  context 'with bad request errors' do
    it 'maps parameter and format errors to bad_request' do
      [
        "user_id parameter is required",
        "Invalid start_time format",
        "Some other unspecified error"  # Default case
      ].each do |error_msg|
        allow(validator).to receive(:error_message).and_return(error_msg)
        expect(validator.error_status).to eq(:bad_request), "Expected '#{error_msg}' to map to :bad_request"
      end
    end
  end

  context 'with not found errors' do
    it 'maps not found errors to not_found' do
      [
        "User not found",
        "Sleep record not found"
      ].each do |error_msg|
        allow(validator).to receive(:error_message).and_return(error_msg)
        expect(validator.error_status).to eq(:not_found), "Expected '#{error_msg}' to map to :not_found"
      end
    end
  end

  context 'with forbidden errors' do
    it 'maps authorization errors to forbidden' do
      [
        "You are not authorized to update this sleep record",
        "Not authorized to access this resource"
      ].each do |error_msg|
        allow(validator).to receive(:error_message).and_return(error_msg)
        expect(validator.error_status).to eq(:forbidden), "Expected '#{error_msg}' to map to :forbidden"
      end
    end
  end

  context 'with unprocessable entity errors' do
    it 'maps validation errors to unprocessable_entity' do
      [
        "Start time cannot be in the future",
        "End time cannot be in the future",
        "You already have an in-progress sleep record",
        "Start time overlaps with another sleep record",
        "Sleep record is already completed",
        "End time must be after start time"
      ].each do |error_msg|
        allow(validator).to receive(:error_message).and_return(error_msg)
        expect(validator.error_status).to eq(:unprocessable_entity), "Expected '#{error_msg}' to map to :unprocessable_entity"
      end
    end
  end
end

  describe '#validate_end_action' do
    describe 'parameter validation' do
      context 'with missing user_id' do
        let(:params) { {} }
        let(:sleep_record) { create(:sleep_record) }

        it 'fails validation with correct error' do
          validator = described_class.new(params)
          expect(validator.validate_end_action(sleep_record.id)).to be false
          expect(validator.error_message).to match(/user_id parameter is required/i)
          expect(validator.error_status).to eq(:bad_request)
        end
      end

      context 'with non-existent user_id' do
        let(:params) { { user_id: 999999 } }
        let(:sleep_record) { create(:sleep_record) }

        it 'fails validation with correct error' do
          validator = described_class.new(params)
          expect(validator.validate_end_action(sleep_record.id)).to be false
          expect(validator.error_message).to match(/user not found/i)
          expect(validator.error_status).to eq(:not_found)
        end
      end
    end

    describe 'sleep record validation' do
      let(:user) { create(:user) }

      context 'with non-existent sleep record' do
        let(:params) { { user_id: user.id } }

        it 'fails validation with correct error' do
          validator = described_class.new(params)
          expect(validator.validate_end_action(999999)).to be false
          expect(validator.error_message).to match(/sleep record not found/i)
          expect(validator.error_status).to eq(:not_found)
        end
      end

      context 'when sleep record belongs to different user' do
        let(:params) { { user_id: user.id } }
        let(:other_user) { create(:user) }
        let(:sleep_record) { create(:sleep_record, user: other_user) }

        it 'fails validation with authorization error' do
          # Swap the users so record doesn't belong to the requesting user
          validator = described_class.new({ user_id: create(:user).id })
          expect(validator.validate_end_action(sleep_record.id)).to be false
          expect(validator.error_message).to match(/not authorized/i)
          expect(validator.error_status).to eq(:forbidden)
        end
      end

      context 'when sleep record is already completed' do
        let(:params) { { user_id: user.id } }
        let(:completed_record) { create(:sleep_record, user: user, start_time: 3.hours.ago, end_time: 1.hour.ago) }

        it 'fails validation with already completed error' do
          validator = described_class.new(params)
          expect(validator.validate_end_action(completed_record.id)).to be false
          expect(validator.error_message).to match(/already completed/i)
          expect(validator.error_status).to eq(:unprocessable_entity)
        end
      end
    end

    describe 'end time validation' do
      let(:user) { create(:user) }
      let(:sleep_record) { create(:sleep_record, user: user, start_time: 2.hours.ago, end_time: nil) }

      context 'with future end_time' do
        let(:params) { { user_id: user.id, end_time: 1.hour.from_now.iso8601 } }

        it 'fails validation with future time error' do
          validator = described_class.new(params)
          expect(validator.validate_end_action(sleep_record.id)).to be false
          expect(validator.error_message).to match(/cannot be in the future/i)
          expect(validator.error_status).to eq(:unprocessable_entity)
        end
      end

      context 'with end_time before start_time' do
        let(:params) { { user_id: user.id, end_time: (sleep_record.start_time - 30.minutes).iso8601 } }

        it 'fails validation with before start time error' do
          validator = described_class.new(params)
          expect(validator.validate_end_action(sleep_record.id)).to be false
          expect(validator.error_message).to match(/must be after start time/i)
          expect(validator.error_status).to eq(:unprocessable_entity)
        end
      end

      context 'with invalid end_time format' do
        let(:params) { { user_id: user.id, end_time: 'not-a-date' } }

        it 'fails validation with format error' do
          validator = described_class.new(params)
          expect(validator.validate_end_action(sleep_record.id)).to be false
          expect(validator.error_message).to match(/invalid.*format/i)
          expect(validator.error_status).to eq(:bad_request)
        end
      end
    end

    describe 'successful validation' do
      let(:user) { create(:user) }
      let(:sleep_record) { create(:sleep_record, user: user, start_time: 2.hours.ago, end_time: nil) }

      context 'with valid end_time' do
        let(:valid_end_time) { Time.current - 5.minutes }
        let(:params) { { user_id: user.id, end_time: valid_end_time.iso8601 } }

        it 'passes validation and sets objects correctly' do
          validator = described_class.new(params)
          expect(validator.validate_end_action(sleep_record.id)).to be true
          expect(validator.error_message).to be_nil
          expect(validator.user).to eq(user)
          expect(validator.sleep_record).to eq(sleep_record)
          expect(validator.end_time).to be_within(1.second).of(valid_end_time)
        end
      end

      context 'with no end_time (using current time)' do
        let(:params) { { user_id: user.id } }

        it 'passes validation with nil end_time (using current time)' do
          validator = described_class.new(params)
          expect(validator.validate_end_action(sleep_record.id)).to be true
          expect(validator.user).to eq(user)
          expect(validator.sleep_record).to eq(sleep_record)
          expect(validator.end_time).to be_nil
        end
      end
    end
  end
end
