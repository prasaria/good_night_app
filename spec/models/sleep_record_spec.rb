# spec/models/sleep_record_spec.rb
require 'rails_helper'

RSpec.describe SleepRecord, type: :model do
  # Factory validation
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:sleep_record)).to be_valid
    end

    it 'has a valid factory with completed trait' do
      expect(build(:sleep_record, :completed)).to be_valid
    end

    it 'has a valid factory with last_week trait' do
      expect(build(:sleep_record, :last_week)).to be_valid
    end
  end

  # Validations
  describe 'validations' do
    it { is_expected.to validate_presence_of(:start_time) }

    it 'validates that end_time is after start_time' do
      sleep_record = build(:sleep_record, start_time: Time.current, end_time: 1.hour.ago)
      expect(sleep_record).not_to be_valid
      expect(sleep_record.errors[:end_time]).to include("must be after start time")
    end

    it 'allows null end_time' do
      sleep_record = build(:sleep_record, end_time: nil)
      expect(sleep_record).to be_valid
    end

    it 'prevents overlapping sleep records for the same user' do
      user = create(:user)
      create(:sleep_record,
             user: user,
             start_time: 2.hours.ago,
             end_time: 1.hour.ago)

      # Attempt to create an overlapping record
      overlapping_record = build(:sleep_record,
                               user: user,
                               start_time: 1.5.hours.ago)

      expect(overlapping_record).not_to be_valid
      expect(overlapping_record.errors[:start_time]).to include("overlaps with another sleep record")
    end

    it 'allows non-overlapping sleep records for the same user' do
      user = create(:user)
      create(:sleep_record,
             user: user,
             start_time: 3.hours.ago,
             end_time: 2.hours.ago)

      # Create a non-overlapping record
      non_overlapping_record = build(:sleep_record,
                                   user: user,
                                   start_time: 1.hour.ago)

      expect(non_overlapping_record).to be_valid
    end

    it 'allows overlapping sleep records for different users' do
      create(:sleep_record,
             user: create(:user),
             start_time: 2.hours.ago,
             end_time: 1.hour.ago)

      # Create an overlapping record for a different user
      overlapping_record_different_user = build(:sleep_record,
                                              user: create(:user),
                                              start_time: 1.5.hours.ago)

      expect(overlapping_record_different_user).to be_valid
    end
  end

  # Associations
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  # Scopes
  describe 'scopes' do
    describe '.completed' do
      it 'returns only sleep records with end_time' do
        completed_record = create(:sleep_record, :completed)
        in_progress_record = create(:sleep_record)

        expect(described_class.completed).to include(completed_record)
        expect(described_class.completed).not_to include(in_progress_record)
      end
    end

    describe '.in_progress' do
      it 'returns only sleep records without end_time' do
        completed_record = create(:sleep_record, :completed)
        in_progress_record = create(:sleep_record)

        expect(described_class.in_progress).to include(in_progress_record)
        expect(described_class.in_progress).not_to include(completed_record)
      end
    end

    describe '.for_user' do
      it 'returns sleep records for the specified user' do
        user1 = create(:user)
        user2 = create(:user)
        record1 = create(:sleep_record, user: user1)
        record2 = create(:sleep_record, user: user2)

        expect(described_class.for_user(user1.id)).to include(record1)
        expect(described_class.for_user(user1.id)).not_to include(record2)
      end
    end

    describe '.recent' do
      it 'returns sleep records ordered by creation time (newest first)' do
        record1 = create(:sleep_record)
        record2 = create(:sleep_record)

        expect(described_class.recent.to_a).to eq([ record2, record1 ])
      end

      it 'limits results when limit is provided' do
        create_list(:sleep_record, 3)

        expect(described_class.recent(2).size).to eq(2)
      end
    end

    describe '.from_last_week' do
      it 'returns sleep records from the last 7 days' do
        last_week_record = create(:sleep_record, :last_week)
        two_weeks_ago = create(:sleep_record, start_time: 2.weeks.ago, end_time: 2.weeks.ago + 8.hours)
        yesterday = create(:sleep_record, start_time: 1.day.ago, end_time: 16.hours.ago)

        expect(described_class.from_last_week).to include(yesterday)
        expect(described_class.from_last_week).to include(last_week_record)
        expect(described_class.from_last_week).not_to include(two_weeks_ago)
      end
    end
  end

  # Callbacks
  describe 'callbacks' do
    describe 'before_save' do
      it 'calculates duration_minutes when end_time is set' do
        sleep_record = create(:sleep_record, start_time: 8.hours.ago, end_time: nil)

        # Update with an end time
        sleep_record.end_time = Time.current
        sleep_record.save

        # Expected duration: 8 hours in minutes (approximately)
        expected_minutes = (8 * 60).to_i
        # Allow small differences due to test execution time
        expect(sleep_record.duration_minutes).to be_within(2).of(expected_minutes)
      end

      it 'does not calculate duration_minutes when end_time is not set' do
        sleep_record = create(:sleep_record)
        expect(sleep_record.duration_minutes).to be_nil
      end
    end
  end

  # Instance methods
  describe '#complete?' do
    it 'sets the end_time and calculates duration' do
      sleep_record = create(:sleep_record, start_time: 8.hours.ago)
      end_time = Time.current

      sleep_record.complete?(end_time)

      expect(sleep_record.end_time).to eq(end_time)
      expected_minutes = (8 * 60).to_i
      expect(sleep_record.duration_minutes).to be_within(2).of(expected_minutes)
    end

    it 'returns true when successfully completed' do
      sleep_record = create(:sleep_record, start_time: 8.hours.ago)
      expect(sleep_record).to be_complete(Time.current)
    end

    it 'returns false when end_time is before start_time' do
      sleep_record = create(:sleep_record, start_time: 1.hour.ago)
      expect(sleep_record).not_to be_complete(2.hours.ago)
    end
  end
end
