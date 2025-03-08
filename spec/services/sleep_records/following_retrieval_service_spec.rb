# spec/services/sleep_records/following_retrieval_service_spec.rb
require 'rails_helper'

RSpec.describe SleepRecords::FollowingRetrievalService do
  describe '#call' do
    let(:user) { create(:user) }
    let(:first_followed_user) { create(:user) }
    let(:second_followed_user) { create(:user) }
    let(:unfollowed_user) { create(:user) }

    before do
      # Create following relationships
      create(:following, follower: user, followed: first_followed_user)
      create(:following, follower: user, followed: second_followed_user)

      # Create sleep records for followed users
      create(:sleep_record, user: first_followed_user, start_time: 1.day.ago, end_time: 16.hours.ago, duration_minutes: 8 * 60)
      create(:sleep_record, user: first_followed_user, start_time: 3.days.ago, end_time: (3.days.ago + 7.hours), duration_minutes: 7 * 60)
      create(:sleep_record, user: second_followed_user, start_time: 2.days.ago, end_time: (2.days.ago + 6.hours), duration_minutes: 6 * 60)
      create(:sleep_record, user: second_followed_user, start_time: 8.days.ago, end_time: (8.days.ago + 5.hours), duration_minutes: 5 * 60)

      # Create records for an unfollowed user
      create(:sleep_record, user: unfollowed_user, start_time: 1.day.ago, end_time: 16.hours.ago, duration_minutes: 8 * 60)

      # Create in-progress records
      create(:sleep_record, user: first_followed_user, start_time: 2.hours.ago, end_time: nil)
    end

    context 'when user is not provided' do
      it 'raises BadRequestError' do
        service = described_class.new(user: nil)

        expect {
          service.call
        }.to raise_error(Exceptions::BadRequestError, /User is required/i)
      end
    end

    context 'when retrieving records with default options' do
      it 'returns sleep records from followed users' do
        service = described_class.new(user: user)
        result = service.call

        expect(result[:records].length).to eq(5)  # All records from followed users

        # Verify all records belong to followed users
        user_ids = result[:records].map(&:user_id).uniq
        expect(user_ids).to contain_exactly(first_followed_user.id, second_followed_user.id)
      end

      it 'orders records by created_at descending by default' do
        service = described_class.new(user: user)
        result = service.call

        expect(result[:records].first.created_at).to be > result[:records].last.created_at
      end
    end

    context 'when filtering by completion status' do
      it 'returns only completed records when requested' do
        service = described_class.new(user: user, completed_only: true)
        result = service.call

        expect(result[:records].length).to eq(4)  # 4 completed records from followed users
        expect(result[:records]).to all(be_completed)
      end

      it 'returns only in-progress records when requested' do
        service = described_class.new(user: user, in_progress_only: true)
        result = service.call

        expect(result[:records].length).to eq(1)  # 1 in-progress record from followed users
        expect(result[:records].first.end_time).to be_nil
      end
    end

    context 'when filtering by date range' do
      it 'returns records from last week' do
        service = described_class.new(user: user, from_last_week: true)
        result = service.call

        expect(result[:records].length).to eq(4)  # 4 records within last week
        expect(result[:records].map(&:start_time)).to all(be > 1.week.ago)
      end
    end

    context 'when sorting records' do
      it 'sorts by duration in ascending order' do
        service = described_class.new(user: user, sort_by: 'duration', sort_direction: 'asc')
        result = service.call

        # Get completed records only
        completed_records = result[:records].select(&:completed?)
        durations = completed_records.map(&:duration_minutes)

        # Check if durations are in non-decreasing order
        expect(durations.each_cons(2).all? { |a, b| a <= b }).to be true
      end

      it 'sorts by duration in descending order' do
        service = described_class.new(user: user, sort_by: 'duration', sort_direction: 'desc')
        result = service.call

        # Get completed records only
        completed_records = result[:records].select(&:completed?)
        durations = completed_records.map(&:duration_minutes)

        # Check if durations are in non-increasing order
        expect(durations.each_cons(2).all? { |a, b| a >= b }).to be true
      end
    end

    context 'when limiting results' do
      it 'limits the number of records returned' do
        service = described_class.new(user: user, limit: 2)
        result = service.call

        expect(result[:records].length).to eq(2)
      end
    end

    context 'when paginating results' do
      it 'returns the specified page of records' do
        service = described_class.new(user: user, page: 2, per_page: 2)
        result = service.call

        expect(result[:records].length).to eq(2)  # 2 records per page
        expect(result[:pagination][:current_page]).to eq(2)
        expect(result[:pagination][:total_pages]).to eq(3)  # 5 records total, 2 per page = 3 pages
      end

      it 'includes pagination metadata' do
        service = described_class.new(user: user, page: 1, per_page: 2)
        result = service.call

        expect(result[:pagination]).to include(
          current_page: 1,
          total_pages: 3,
          total_count: 5,
          per_page: 2
        )
      end
    end

    context 'when filtering by specific followed users' do
      it 'returns records from specific followed users when provided' do
        service = described_class.new(user: user, followed_user_ids: [ first_followed_user.id ])
        result = service.call

        expect(result[:records].length).to eq(3)  # 3 records from first_followed_user
        expect(result[:records].map(&:user_id).uniq).to eq([ first_followed_user.id ])
      end
    end

    context 'when user follows no one' do
      let(:lonely_user) { create(:user) }

      it 'returns an empty array of records' do
        service = described_class.new(user: lonely_user)
        result = service.call

        expect(result[:records]).to be_empty
      end
    end
  end
end
