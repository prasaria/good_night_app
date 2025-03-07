# spec/services/followings/create_service_spec.rb
require 'rails_helper'

RSpec.describe Followings::CreateService do
  describe '#call' do
    let(:follower) { create(:user) }
    let(:followed) { create(:user) }

    context 'when successful' do
      it 'creates a new following relationship' do
        service = described_class.new(follower: follower, followed: followed)

        expect {
          result = service.call
          expect(result.success?).to be true
        }.to change(Following, :count).by(1)
      end

      it 'returns the created following' do
        service = described_class.new(follower: follower, followed: followed)
        result = service.call

        expect(result.following).to be_a(Following)
        expect(result.following).to be_persisted
      end

      it 'sets the correct follower and followed users' do
        service = described_class.new(follower: follower, followed: followed)
        result = service.call

        expect(result.following.follower).to eq(follower)
        expect(result.following.followed).to eq(followed)
      end
    end

    context 'when users are the same' do
      it 'returns an error' do
        service = described_class.new(follower: follower, followed: follower)
        result = service.call

        expect(result.success?).to be false
        expect(result.errors).to include("You cannot follow yourself")
      end

      it 'does not create a following relationship' do
        service = described_class.new(follower: follower, followed: follower)

        expect {
          service.call
        }.not_to change(Following, :count)
      end
    end

    context 'when already following' do
      before do
        create(:following, follower: follower, followed: followed)
      end

      it 'returns an error' do
        service = described_class.new(follower: follower, followed: followed)
        result = service.call

        expect(result.success?).to be false
        expect(result.errors).to include("You are already following this user")
      end

      it 'does not create a duplicate following relationship' do
        service = described_class.new(follower: follower, followed: followed)

        expect {
          service.call
        }.not_to change(Following, :count)
      end
    end

    context 'when follower is nil' do
      it 'returns an error' do
        service = described_class.new(follower: nil, followed: followed)
        result = service.call

        expect(result.success?).to be false
        expect(result.errors).to include("Follower is required")
      end
    end

    context 'when followed is nil' do
      it 'returns an error' do
        service = described_class.new(follower: follower, followed: nil)
        result = service.call

        expect(result.success?).to be false
        expect(result.errors).to include("Followed user is required")
      end
    end

    context 'when validation fails' do
      it 'returns the validation errors' do
        # Create a real Following object with validation errors
        following = build(:following, follower: follower, followed: followed)

        # Add a validation error to it
        following.errors.add(:base, "Custom validation error")

        # Stub the save method to return false
        allow(following).to receive(:save).and_return(false)

        # Stub Following.new to return our prepared object
        allow(Following).to receive(:new).and_return(following)

        service = described_class.new(follower: follower, followed: followed)
        result = service.call

        expect(result.success?).to be false
        expect(result.errors).to include("Custom validation error")
      end
    end
  end
end
