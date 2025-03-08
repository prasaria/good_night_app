# spec/validators/api/v1/followings_sleep_records_validator_spec.rb
require 'rails_helper'

RSpec.describe Api::V1::FollowingsSleepRecordsValidator do
  describe '#validate_index_action' do
    context 'with missing user_id' do
      it 'raises BadRequestError' do
        validator = described_class.new({})

        expect {
          validator.validate_index_action
        }.to raise_error(Exceptions::BadRequestError, /user_id parameter is required/i)
      end
    end

    context 'with non-existent user_id' do
      it 'raises NotFoundError' do
        validator = described_class.new({ user_id: 999999 })

        expect {
          validator.validate_index_action
        }.to raise_error(Exceptions::NotFoundError, /User not found/i)
      end
    end

    context 'with invalid date formats' do
      let(:user) { create(:user) }

      it 'raises BadRequestError for invalid start_date' do
        validator = described_class.new({
          user_id: user.id,
          start_date: 'not-a-date'
        })

        expect {
          validator.validate_index_action
        }.to raise_error(Exceptions::BadRequestError, /Invalid start_date format/i)
      end

      it 'raises BadRequestError for invalid end_date' do
        validator = described_class.new({
          user_id: user.id,
          end_date: 'not-a-date'
        })

        expect {
          validator.validate_index_action
        }.to raise_error(Exceptions::BadRequestError, /Invalid end_date format/i)
      end
    end

    context 'when start_date is after end_date' do
      let(:user) { create(:user) }
      let(:params) { {
        user_id: user.id,
        start_date: 1.day.ago.iso8601,
        end_date: 3.days.ago.iso8601
      } }

      it 'raises BadRequestError' do
        validator = described_class.new(params)

        expect {
          validator.validate_index_action
        }.to raise_error(Exceptions::BadRequestError, /start_date must be before end_date/i)
      end
    end

    context 'with valid parameters' do
      let(:user) { create(:user) }

      it 'returns true with just user_id' do
        validator = described_class.new({ user_id: user.id })

        expect(validator.validate_index_action).to be true
        expect(validator.user).to eq(user)
      end

      it 'returns true with valid date range' do
        validator = described_class.new({
          user_id: user.id,
          start_date: 3.days.ago.iso8601,
          end_date: 1.day.ago.iso8601
        })

        expect(validator.validate_index_action).to be true
        expect(validator.start_date).to be_within(1.second).of(3.days.ago)
        expect(validator.end_date).to be_within(1.second).of(1.day.ago)
      end
    end
  end
end
