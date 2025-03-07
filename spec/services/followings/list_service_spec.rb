# spec/services/followings/list_service_spec.rb
require 'rails_helper'

RSpec.describe Followings::ListService do
  describe '#call' do
    let(:user) { create(:user) }

    context 'when user has followings' do
      before do
        # Create 15 followed users to test pagination
        15.times do |i|
          followed_user = create(:user, name: "Followed User #{i+1}")
          create(:following, follower: user, followed: followed_user)
        end
      end

      it 'returns list of users the given user follows' do
        service = described_class.new(user: user)
        result = service.call

        expect(result.success?).to be true
        expect(result.followed_users).to all(be_a(User))
        expect(result.followed_users.count).to eq(15)
      end

      it 'paginates results when page parameter is provided' do
        service = described_class.new(user: user, page: 2, per_page: 5)
        result = service.call

        expect(result.success?).to be true
        expect(result.followed_users.count).to eq(5)  # 5 per page
        expect(result.pagination[:current_page]).to eq(2)
        expect(result.pagination[:total_pages]).to eq(3)  # 15 users, 5 per page = 3 pages
      end

      it 'handles the last page correctly' do
        service = described_class.new(user: user, page: 3, per_page: 5)
        result = service.call

        expect(result.success?).to be true
        expect(result.followed_users.count).to eq(5)  # 5 on the last page
        expect(result.pagination[:current_page]).to eq(3)
        expect(result.pagination[:is_last_page]).to be true
      end

      it 'returns empty array for page beyond total pages' do
        service = described_class.new(user: user, page: 4, per_page: 5)
        result = service.call

        expect(result.success?).to be true
        expect(result.followed_users).to be_empty
        expect(result.pagination[:current_page]).to eq(4)
        expect(result.pagination[:total_pages]).to eq(3)
      end

      it 'includes pagination metadata' do
        service = described_class.new(user: user, page: 1, per_page: 10)
        result = service.call

        expect(result.pagination).to include(
          current_page: 1,
          total_pages: 2,
          total_count: 15,
          per_page: 10
        )
      end

      it 'sorts users by name by default' do
        service = described_class.new(user: user, sort_by: 'name')
        result = service.call

        names = result.followed_users.map(&:name)
        expect(names).to eq(names.sort)
      end

      it 'allows sorting by most recently followed' do
        service = described_class.new(user: user, sort_by: 'recent')
        result = service.call

        followed_ids = result.followed_users.map(&:id)
        following_created_order = user.followings.order(created_at: :desc).map(&:followed_id)
        expect(followed_ids).to eq(following_created_order)
      end
    end

    context 'when user has no followings' do
      it 'returns an empty array' do
        service = described_class.new(user: user)
        result = service.call

        expect(result.success?).to be true
        expect(result.followed_users).to be_empty
        expect(result.pagination[:total_count]).to eq(0)
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
