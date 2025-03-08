# spec/validators/api/v1/followings_validator_spec.rb
require 'rails_helper'

RSpec.describe Api::V1::FollowingsValidator do
  describe '#validate_create_action' do
    context 'with missing parameters' do
      it 'raises BadRequestError when follower_id is missing' do
        validator = described_class.new({ followed_id: 1 })

        expect {
          validator.validate_create_action
        }.to raise_error(Exceptions::BadRequestError, /follower_id parameter is required/i)
      end

      it 'raises BadRequestError when followed_id is missing' do
        validator = described_class.new({ follower_id: 1 })

        expect {
          validator.validate_create_action
        }.to raise_error(Exceptions::BadRequestError, /followed_id parameter is required/i)
      end
    end

    context 'with non-existent users' do
      it 'raises NotFoundError when follower does not exist' do
        validator = described_class.new({ follower_id: 999999, followed_id: 1 })

        expect {
          validator.validate_create_action
        }.to raise_error(Exceptions::NotFoundError, /Follower user not found/i)
      end

      it 'raises NotFoundError when followed does not exist' do
        follower = create(:user)
        validator = described_class.new({ follower_id: follower.id, followed_id: 999999 })

        expect {
          validator.validate_create_action
        }.to raise_error(Exceptions::NotFoundError, /Followed user not found/i)
      end
    end

    context 'with invalid follow scenarios' do
      let(:user) { create(:user) }

      it 'raises UnprocessableEntityError when trying to self-follow' do
        validator = described_class.new({ follower_id: user.id, followed_id: user.id })

        expect {
          validator.validate_create_action
        }.to raise_error(Exceptions::UnprocessableEntityError, /cannot follow yourself/i)
      end

      it 'raises UnprocessableEntityError when already following' do
        followed = create(:user)
        create(:following, follower: user, followed: followed)

        validator = described_class.new({ follower_id: user.id, followed_id: followed.id })

        expect {
          validator.validate_create_action
        }.to raise_error(Exceptions::UnprocessableEntityError, /already following/i)
      end
    end

    context 'with valid parameters' do
      it 'passes validation and sets user objects' do
        follower = create(:user)
        followed = create(:user)

        validator = described_class.new({ follower_id: follower.id, followed_id: followed.id })
        expect(validator.validate_create_action).to be true

        expect(validator.follower).to eq(follower)
        expect(validator.followed).to eq(followed)
      end
    end
  end
end
