# spec/services/sleep_records/retrieval_service_spec.rb
require 'rails_helper'

RSpec.describe SleepRecords::RetrievalService do
  describe '#call' do
    let(:user) { create(:user) }

    before do
      # Create a mix of records for testing
      create(:sleep_record, user: user, start_time: 1.day.ago, end_time: 18.hours.ago, duration_minutes: 6 * 60)
      create(:sleep_record, user: user, start_time: 2.days.ago, end_time: 42.hours.ago, duration_minutes: 6 * 60)
      create(:sleep_record, user: user, start_time: 3.days.ago, end_time: 66.hours.ago, duration_minutes: 6 * 60)
      create(:sleep_record, user: user, start_time: 8.days.ago, end_time: 7.9.days.ago, duration_minutes: 2 * 60)
      create(:sleep_record, user: user, start_time: 2.hours.ago, end_time: nil)

      # Create records for another user
      other_user = create(:user)
      create(:sleep_record, user: other_user, start_time: 1.day.ago, end_time: 20.hours.ago)
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
      it 'returns all sleep records for the user' do
        service = described_class.new(user: user)
        result = service.call

        expect(result[:records].length).to eq(5)
        expect(result[:records]).to all(be_a(SleepRecord))
        expect(result[:records]).to all(have_attributes(user_id: user.id))
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

        expect(result[:records].length).to eq(4)
        expect(result[:records]).to all(be_completed)
      end

      it 'returns only in-progress records when requested' do
        service = described_class.new(user: user, in_progress_only: true)
        result = service.call

        expect(result[:records].length).to eq(1)
        expect(result[:records].first.end_time).to be_nil
      end
    end

    context 'when filtering by date range' do
      it 'returns records from last week' do
        service = described_class.new(user: user, from_last_week: true)
        result = service.call

        expect(result[:records].length).to eq(4) # 4 records within last week
        expect(result[:records].map(&:start_time)).to all(be > 1.week.ago)
      end

      it 'returns records from custom start date' do
        service = described_class.new(user: user, start_date: 2.days.ago)
        result = service.call

        expect(result[:records].length).to eq(2) # 2 records from last 2 days
        expect(result[:records].map(&:start_time)).to all(be > 2.days.ago)
      end

      it 'returns records until custom end date' do
        service = described_class.new(user: user, end_date: 4.days.ago)
        result = service.call

        expect(result[:records].length).to eq(1) # 1 record before 4 days ago
        expect(result[:records].map(&:start_time)).to all(be < 4.days.ago)
      end

      it 'returns records within custom date range' do
        service = described_class.new(user: user, start_date: 4.days.ago, end_date: 1.day.ago)
        result = service.call

        expect(result[:records].length).to eq(3) # 3 records between 4 and 1 days ago
        records_in_range = result[:records].all? do |record|
          record.start_time > 4.days.ago && record.start_time < 1.day.ago
        end
        expect(records_in_range).to be true
      end
    end

    context 'when sorting records' do
      it 'sorts by duration in ascending order' do
        service = described_class.new(user: user, sort_by: 'duration', sort_direction: 'asc')
        result = service.call

        completed_records = result[:records].select(&:completed?)
        durations = completed_records.map(&:duration_minutes)
        expect(durations).to eq(durations.sort)
      end

      it 'sorts by duration in descending order' do
        service = described_class.new(user: user, sort_by: 'duration', sort_direction: 'desc')
        result = service.call

        completed_records = result[:records].select(&:completed?)
        durations = completed_records.map(&:duration_minutes)
        expect(durations).to eq(durations.sort.reverse)
      end

      it 'sorts by start_time' do
        service = described_class.new(user: user, sort_by: 'start_time', sort_direction: 'asc')
        result = service.call

        start_times = result[:records].map(&:start_time)
        expect(start_times).to eq(start_times.sort)
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
  end
end
