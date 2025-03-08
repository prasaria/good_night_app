# spec/services/followings/remove_service_spec.rb
require 'rails_helper'

RSpec.describe Followings::RemoveService do
  describe '#call' do
    let(:follower) { create(:user) }
    let(:followed) { create(:user) }

    context 'when a following relationship exists' do
      it 'removes the following relationship' do
        # Create following inside the test that uses it
        _following = create(:following, follower: follower, followed: followed)

        service = described_class.new(follower: follower, followed: followed)

        expect {
          result = service.call
          expect(result[:message]).to include("Successfully unfollowed")
        }.to change(Following, :count).by(-1)
      end

      it 'returns success message' do
        # Create following inside the test that uses it
        _following = create(:following, follower: follower, followed: followed)

        service = described_class.new(follower: follower, followed: followed)
        result = service.call

        expect(result[:message]).to include("Successfully unfollowed")
        expect(result[:following]).to be_a(Following)
      end
    end

    context 'when removing by following ID' do
      it 'removes the following relationship' do
        # Create following inside the test that uses it
        following = create(:following, follower: follower, followed: followed)

        service = described_class.new(id: following.id)

        expect {
          result = service.call
          expect(result[:message]).to include("Successfully unfollowed")
        }.to change(Following, :count).by(-1)
      end

      it 'returns success message' do
        # Create following inside the test that uses it
        following = create(:following, follower: follower, followed: followed)

        service = described_class.new(id: following.id)
        result = service.call

        expect(result[:message]).to include("Successfully unfollowed")
      end
    end

    context 'when no following relationship exists' do
      it 'raises NotFoundError' do
        service = described_class.new(follower: follower, followed: followed)

        expect {
          service.call
        }.to raise_error(Exceptions::NotFoundError, /Following relationship not found/)
      end

      it 'does not change following count' do
        service = described_class.new(follower: follower, followed: followed)

        expect {
          begin
            service.call
          rescue Exceptions::NotFoundError
            # Expected error
          end
        }.not_to change(Following, :count)
      end
    end

    context 'when following ID does not exist' do
      it 'raises NotFoundError' do
        service = described_class.new(id: 999999)

        expect {
          service.call
        }.to raise_error(Exceptions::NotFoundError, /Following relationship not found/)
      end
    end

    context 'when invalid parameters are provided' do
      it 'raises BadRequestError when neither users nor ID is provided' do
        service = described_class.new

        expect {
          service.call
        }.to raise_error(Exceptions::BadRequestError, /Must provide either following ID or both follower and followed users/)
      end

      it 'raises BadRequestError when only follower is provided' do
        service = described_class.new(follower: follower)

        expect {
          service.call
        }.to raise_error(Exceptions::BadRequestError, /Must provide both follower and followed users/)
      end

      it 'raises BadRequestError when only followed is provided' do
        service = described_class.new(followed: followed)

        expect {
          service.call
        }.to raise_error(Exceptions::BadRequestError, /Must provide both follower and followed users/)
      end
    end

    context 'when deletion fails for some reason' do
      it 'raises UnprocessableEntityError' do
        # Create following inside the test
        following = create(:following, follower: follower, followed: followed)

        # Find the following and stub its destroy method
        # This avoids using allow_any_instance_of
        allow(Following).to receive(:find_by).and_return(following)
        allow(following).to receive(:destroy).and_return(false)

        service = described_class.new(follower: follower, followed: followed)

        expect {
          service.call
        }.to raise_error(Exceptions::UnprocessableEntityError, /Failed to unfollow user/)
      end
    end
  end
end
