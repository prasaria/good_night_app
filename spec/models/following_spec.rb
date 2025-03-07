# spec/models/following_spec.rb
require 'rails_helper'

RSpec.describe Following, type: :model do
  # Factory validation
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:following)).to be_valid
    end
  end

  # Validations
  describe 'validations' do
    it 'validates uniqueness of follower_id scoped to followed_id' do
      user1 = create(:user)
      user2 = create(:user)
      create(:following, follower: user1, followed: user2)

      duplicate = build(:following, follower: user1, followed: user2)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:follower_id]).to include("has already been taken")
    end

    it 'prevents a user from following themselves' do
      user = create(:user)
      self_follow = build(:following, follower: user, followed: user)

      expect(self_follow).not_to be_valid
      expect(self_follow.errors[:followed_id]).to include("can't follow yourself")
    end

    it 'requires follower_id to be present' do
      expect(build(:following, follower: nil)).not_to be_valid
    end

    it 'requires followed_id to be present' do
      expect(build(:following, followed: nil)).not_to be_valid
    end
  end

  # Associations
  describe 'associations' do
    it { is_expected.to belong_to(:follower).class_name('User') }
    it { is_expected.to belong_to(:followed).class_name('User') }
  end

  # Database constraints
  describe 'database constraints' do
    it 'has a unique index on follower_id and followed_id' do
      user1 = create(:user)
      user2 = create(:user)
      create(:following, follower: user1, followed: user2)

      # Attempt to create a duplicate record that bypasses ActiveRecord validations
      expect {
        described_class.connection.execute(
          "INSERT INTO followings (follower_id, followed_id, created_at, updated_at)
           VALUES (#{user1.id}, #{user2.id}, NOW(), NOW())"
        )
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  # Behavioral tests
  describe 'behavior' do
    it 'allows a user to follow multiple users' do
      follower = create(:user)
      followed1 = create(:user)
      followed2 = create(:user)

      _following1 = create(:following, follower: follower, followed: followed1)
      _following2 = create(:following, follower: follower, followed: followed2)

      expect(follower.followed_users).to include(followed1, followed2)
    end

    it 'allows a user to be followed by multiple users' do
      followed = create(:user)
      follower1 = create(:user)
      follower2 = create(:user)

      _following1 = create(:following, follower: follower1, followed: followed)
      _following2 = create(:following, follower: follower2, followed: followed)

      expect(followed.followers).to include(follower1, follower2)
    end

    it 'is destroyed when the follower user is destroyed' do
      follower = create(:user)
      followed = create(:user)
      following = create(:following, follower: follower, followed: followed)

      expect {
        follower.destroy
      }.to change(described_class, :count).by(-1)

      expect(described_class).not_to exist(following.id)
    end

    it 'is destroyed when the followed user is destroyed' do
      follower = create(:user)
      followed = create(:user)
      following = create(:following, follower: follower, followed: followed)

      expect {
        followed.destroy
      }.to change(described_class, :count).by(-1)

      expect(described_class).not_to exist(following.id)
    end
  end
end
