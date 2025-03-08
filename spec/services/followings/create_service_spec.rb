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
          following = service.call
          expect(following).to be_a(Following)
          expect(following).to be_persisted
        }.to change(Following, :count).by(1)
      end

      it 'returns the created following' do
        service = described_class.new(follower: follower, followed: followed)
        following = service.call

        expect(following).to be_a(Following)
        expect(following).to be_persisted
      end

      it 'sets the correct follower and followed users' do
        service = described_class.new(follower: follower, followed: followed)
        following = service.call

        expect(following.follower).to eq(follower)
        expect(following.followed).to eq(followed)
      end
    end

    context 'when users are the same' do
      it 'raises UnprocessableEntityError' do
        service = described_class.new(follower: follower, followed: follower)

        expect {
          service.call
        }.to raise_error(Exceptions::UnprocessableEntityError, /cannot follow yourself/i)
      end

      it 'does not create a following relationship' do
        service = described_class.new(follower: follower, followed: follower)

        expect {
          begin
            service.call
          rescue Exceptions::UnprocessableEntityError
            # Expected error
          end
        }.not_to change(Following, :count)
      end
    end

    context 'when already following' do
      before do
        create(:following, follower: follower, followed: followed)
      end

      it 'raises UnprocessableEntityError' do
        service = described_class.new(follower: follower, followed: followed)

        expect {
          service.call
        }.to raise_error(Exceptions::UnprocessableEntityError, /already following/i)
      end

      it 'does not create a duplicate following relationship' do
        service = described_class.new(follower: follower, followed: followed)

        expect {
          begin
            service.call
          rescue Exceptions::UnprocessableEntityError
            # Expected error
          end
        }.not_to change(Following, :count)
      end
    end

    context 'when follower is nil' do
      it 'raises BadRequestError' do
        service = described_class.new(follower: nil, followed: followed)

        expect {
          service.call
        }.to raise_error(Exceptions::BadRequestError, /follower is required/i)
      end
    end

    context 'when followed is nil' do
      it 'raises BadRequestError' do
        service = described_class.new(follower: follower, followed: nil)

        expect {
          service.call
        }.to raise_error(Exceptions::BadRequestError, /followed user is required/i)
      end
    end

    context 'when validation fails' do
      it 'raises UnprocessableEntityError with validation errors' do
        # Create a real Following object with validation errors
        following = build(:following, follower: follower, followed: followed)

        # Add a validation error to it
        following.errors.add(:base, "Custom validation error")

        # Stub the save method to return false
        allow(following).to receive(:save).and_return(false)

        # Stub Following.new to return our prepared object
        allow(Following).to receive(:new).and_return(following)

        service = described_class.new(follower: follower, followed: followed)

        expect {
          service.call
        }.to raise_error(Exceptions::UnprocessableEntityError, /custom validation error/i)
      end
    end
  end
end
