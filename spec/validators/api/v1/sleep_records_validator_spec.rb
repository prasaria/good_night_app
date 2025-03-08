# spec/validators/api/v1/sleep_records_validator_spec.rb
require 'rails_helper'

RSpec.describe Api::V1::SleepRecordsValidator do
  describe '#validate_index_action' do
  context 'with missing user_id' do
    let(:params) { {} }

    it 'raises BadRequestError' do
      validator = described_class.new(params)
      expect { validator.validate_index_action }.to raise_error(
        Exceptions::BadRequestError, /user_id parameter is required/i
      )
    end
  end

  context 'with non-existent user_id' do
    let(:params) { { user_id: 999999 } }

    it 'raises NotFoundError' do
      validator = described_class.new(params)
      expect { validator.validate_index_action }.to raise_error(
        Exceptions::NotFoundError, /user not found/i
      )
    end
  end

  context 'with invalid date formats' do
    let(:user) { create(:user) }

    it 'raises BadRequestError for invalid start_date' do
      validator = described_class.new({ user_id: user.id, start_date: 'not-a-date' })
      expect { validator.validate_index_action }.to raise_error(
        Exceptions::BadRequestError, /invalid start_date format/i
      )
    end

    it 'raises BadRequestError for invalid end_date' do
      validator = described_class.new({ user_id: user.id, end_date: 'not-a-date' })
      expect { validator.validate_index_action }.to raise_error(
        Exceptions::BadRequestError, /invalid end_date format/i
      )
    end
  end

  context 'when start_date is after end_date' do
    let(:user) { create(:user) }
    let(:params) {
      {
        user_id: user.id,
        start_date: 1.day.ago.iso8601,
        end_date: 3.days.ago.iso8601
      }
    }

    it 'raises BadRequestError' do
      validator = described_class.new(params)
      expect { validator.validate_index_action }.to raise_error(
        Exceptions::BadRequestError, /start_date must be before end_date/i
      )
    end
  end

  context 'with valid parameters' do
    let(:user) { create(:user) }
    let(:params) { { user_id: user.id } }

    it 'passes validation' do
      validator = described_class.new(params)
      expect(validator.validate_index_action).to be true
    end

    it 'passes validation with valid date range' do
      validator = described_class.new({
        user_id: user.id,
        start_date: 3.days.ago.iso8601,
        end_date: 1.day.ago.iso8601
      })
      expect(validator.validate_index_action).to be true
    end
  end
end

  describe '#validate_start_action' do
    context 'with missing user_id' do
      let(:params) { {} }

      it 'raises BadRequestError' do
        validator = described_class.new(params)
        expect { validator.validate_start_action }.to raise_error(
          Exceptions::BadRequestError, /user_id parameter is required/i
        )
      end
    end

    context 'with non-existent user_id' do
      let(:params) { { user_id: 999999 } }

      it 'raises NotFoundError' do
        validator = described_class.new(params)
        expect { validator.validate_start_action }.to raise_error(
          Exceptions::NotFoundError, /user not found/i
        )
      end
    end

    context 'with future start_time' do
      let(:user) { create(:user) }
      let(:params) { { user_id: user.id, start_time: 1.hour.from_now.iso8601 } }

      it 'raises UnprocessableEntityError' do
        validator = described_class.new(params)
        expect { validator.validate_start_action }.to raise_error(
          Exceptions::UnprocessableEntityError, /cannot be in the future/i
        )
      end
    end

    context 'with invalid start_time format' do
      let(:user) { create(:user) }
      let(:params) { { user_id: user.id, start_time: 'not-a-date' } }

      it 'raises BadRequestError' do
        validator = described_class.new(params)
        expect { validator.validate_start_action }.to raise_error(
          Exceptions::BadRequestError, /invalid.*format/i
        )
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

  describe '#validate_end_action' do
    describe 'parameter validation' do
      context 'with missing user_id' do
        let(:params) { {} }
        let(:sleep_record) { create(:sleep_record) }

        it 'raises BadRequestError' do
          validator = described_class.new(params)
          expect { validator.validate_end_action(sleep_record.id) }.to raise_error(
            Exceptions::BadRequestError, /user_id parameter is required/i
          )
        end
      end

      context 'with non-existent user_id' do
        let(:params) { { user_id: 999999 } }
        let(:sleep_record) { create(:sleep_record) }

        it 'raises NotFoundError' do
          validator = described_class.new(params)
          expect { validator.validate_end_action(sleep_record.id) }.to raise_error(
            Exceptions::NotFoundError, /user not found/i
          )
        end
      end
    end

    describe 'sleep record validation' do
      let(:user) { create(:user) }

      context 'with non-existent sleep record' do
        let(:params) { { user_id: user.id } }

        it 'raises NotFoundError' do
          validator = described_class.new(params)
          expect { validator.validate_end_action(999999) }.to raise_error(
            Exceptions::NotFoundError, /sleep record not found/i
          )
        end
      end

      context 'when sleep record belongs to different user' do
        let(:params) { { user_id: user.id } }
        let(:other_user) { create(:user) }
        let(:sleep_record) { create(:sleep_record, user: other_user) }

        it 'raises ForbiddenError' do
          # Swap the users so record doesn't belong to the requesting user
          validator = described_class.new({ user_id: create(:user).id })
          expect { validator.validate_end_action(sleep_record.id) }.to raise_error(
            Exceptions::ForbiddenError, /not authorized/i
          )
        end
      end

      context 'when sleep record is already completed' do
        let(:params) { { user_id: user.id } }
        let(:completed_record) { create(:sleep_record, user: user, start_time: 3.hours.ago, end_time: 1.hour.ago) }

        it 'raises UnprocessableEntityError' do
          validator = described_class.new(params)
          expect { validator.validate_end_action(completed_record.id) }.to raise_error(
            Exceptions::UnprocessableEntityError, /already completed/i
          )
        end
      end
    end

    describe 'end time validation' do
      let(:user) { create(:user) }
      let(:sleep_record) { create(:sleep_record, user: user, start_time: 2.hours.ago, end_time: nil) }

      context 'with future end_time' do
        let(:params) { { user_id: user.id, end_time: 1.hour.from_now.iso8601 } }

        it 'raises UnprocessableEntityError' do
          validator = described_class.new(params)
          expect { validator.validate_end_action(sleep_record.id) }.to raise_error(
            Exceptions::UnprocessableEntityError, /cannot be in the future/i
          )
        end
      end

      context 'with end_time before start_time' do
        let(:params) { { user_id: user.id, end_time: (sleep_record.start_time - 30.minutes).iso8601 } }

        it 'raises UnprocessableEntityError' do
          validator = described_class.new(params)
          expect { validator.validate_end_action(sleep_record.id) }.to raise_error(
            Exceptions::UnprocessableEntityError, /must be after start time/i
          )
        end
      end

      context 'with invalid end_time format' do
        let(:params) { { user_id: user.id, end_time: 'not-a-date' } }

        it 'raises BadRequestError' do
          validator = described_class.new(params)
          expect { validator.validate_end_action(sleep_record.id) }.to raise_error(
            Exceptions::BadRequestError, /invalid.*format/i
          )
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
          expect(validator.user).to eq(user)
          expect(validator.sleep_record).to eq(sleep_record)
          expect(validator.end_time).to be_within(1.second).of(valid_end_time)
        end
      end

      context 'with no end_time (using current time)' do
        let(:params) { { user_id: user.id } }

        it 'passes validation with nil end_time' do
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
