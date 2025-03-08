# spec/serializers/user_serializer_spec.rb
require 'rails_helper'

RSpec.describe UserSerializer do
  describe '#as_json' do
    let(:user) { create(:user, name: 'John Doe') }

    it 'serializes basic user attributes' do
      serialized = described_class.new(user).as_json

      expect(serialized).to include(
        id: user.id,
        name: 'John Doe',
        created_at: user.created_at,
        updated_at: user.updated_at
      )
    end

    it 'handles custom options' do
      # Add a custom option to test extensibility
      serialized = described_class.new(user, custom_option: true).as_json

      # The basic serialization should still work even with unused options
      expect(serialized).to include(
        id: user.id,
        name: 'John Doe'
      )
    end

    it 'handles nil user gracefully' do
      # In practice, we should avoid passing nil, but the serializer should not crash
      expect {
        serialized = described_class.new(nil).as_json
        # We expect keys to be nil but the serializer should return a hash without crashing
        expect(serialized).to be_a(Hash)
        expect(serialized[:id]).to be_nil
      }.not_to raise_error
    end
  end

  describe 'performance' do
    it 'serializes users efficiently' do
      # Create users first
      create_list(:user, 10)

      # Load users with a single query
      users = User.all.to_a

      # This should not make any additional queries,
      # as users are already loaded in memory
      expect {
        users.each { |user| described_class.new(user).as_json }
      }.to make_database_queries(count: 0)
    end
  end
end
