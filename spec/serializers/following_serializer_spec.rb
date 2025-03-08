# spec/serializers/following_serializer_spec.rb
require 'rails_helper'

RSpec.describe FollowingSerializer do
  describe '#as_json' do
    let(:follower) { create(:user) }
    let(:followed) { create(:user) }
    let(:following) { create(:following, follower: follower, followed: followed) }

    it 'serializes basic following attributes' do
      serialized = described_class.new(following).as_json

      expect(serialized).to include(
        id: following.id,
        follower_id: follower.id,
        followed_id: followed.id,
        created_at: following.created_at,
        updated_at: following.updated_at
      )

      # Should not include users by default
      expect(serialized).not_to have_key(:follower)
      expect(serialized).not_to have_key(:followed)
    end

    it 'includes user data when requested' do
      serialized = described_class.new(following, include_users: true).as_json

      expect(serialized).to include(:follower, :followed)
      expect(serialized[:follower]).to include(id: follower.id, name: follower.name)
      expect(serialized[:followed]).to include(id: followed.id, name: followed.name)
    end
  end

  describe '.serialize_collection' do
    it 'efficiently serializes multiple followings' do
      user = create(:user)
      followed_users = create_list(:user, 3)

      followings = followed_users.map do |followed|
        create(:following, follower: user, followed: followed)
      end

      serialized = described_class.serialize_collection(followings, include_users: true)

      expect(serialized.size).to eq(3)
      expect(serialized.first).to include(:follower, :followed)

      # Check that all the followed users are correctly included
      followed_ids = serialized.map { |f| f[:followed][:id] }
      expect(followed_ids).to match_array(followed_users.map(&:id))
    end

    it 'avoids N+1 queries when including users' do
      user = create(:user)
      followed_users = create_list(:user, 3)

      _followings = followed_users.map do |followed|
        create(:following, follower: user, followed: followed)
      end

      # Use the includes matcher to verify eager loading
      expect {
        described_class.serialize_collection(Following.all, include_users: true)
      }.to make_database_queries(count: 3) # 1 for followings, 1 for followers, 1 for followed
    end
  end
end
