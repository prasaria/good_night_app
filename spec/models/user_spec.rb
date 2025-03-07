# spec/models/user_spec.rb
require 'rails_helper'

RSpec.describe User, type: :model do
  # Factory validation
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:user)).to be_valid
    end
  end

  # Validations
  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_least(2).is_at_most(100) }
  end

  # Associations
  describe 'associations' do
    it { is_expected.to have_many(:sleep_records).dependent(:destroy) }

    it { is_expected.to have_many(:followings).with_foreign_key('follower_id').dependent(:destroy) }
    it { is_expected.to have_many(:followed_users).through(:followings).source(:followed) }

    it { is_expected.to have_many(:reverse_followings).class_name('Following').with_foreign_key('followed_id').dependent(:destroy) }
    it { is_expected.to have_many(:followers).through(:reverse_followings).source(:follower) }
  end

  # Instance methods
  describe '#follow' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }

    it 'creates a following relationship' do
      expect {
        user.follow(other_user)
      }.to change(Following, :count).by(1)
    end

    it 'does not allow following self' do
      expect {
        user.follow(user)
      }.not_to change(Following, :count)
    end

    it 'does not create duplicate followings' do
      user.follow(other_user)

      expect {
        user.follow(other_user)
      }.not_to change(Following, :count)
    end
  end

  describe '#unfollow' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }

    before do
      user.follow(other_user)
    end

    it 'removes a following relationship' do
      expect {
        user.unfollow(other_user)
      }.to change(Following, :count).by(-1)
    end

    it 'does nothing if not following the user' do
      third_user = create(:user)

      expect {
        user.unfollow(third_user)
      }.not_to change(Following, :count)
    end
  end

  describe '#following?' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }

    it 'returns true if following the user' do
      user.follow(other_user)
      expect(user.following?(other_user)).to be true
    end

    it 'returns false if not following the user' do
      expect(user.following?(other_user)).to be false
    end
  end

  describe '#recent_sleep_records' do
    let(:user) { create(:user) }

    before do
      create_list(:sleep_record, 5, user: user)
    end

    it 'returns sleep records ordered by creation time' do
      expect(user.recent_sleep_records.to_a).to eq(user.sleep_records.order(created_at: :desc).to_a)
    end

    it 'limits results when limit is provided' do
      expect(user.recent_sleep_records(limit: 2).size).to eq(2)
    end
  end
end
