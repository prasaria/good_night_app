# spec/models/user_spec.rb
require 'rails_helper'

RSpec.describe User, type: :model do
  # This test will fail until we create the User model
  it "has a valid factory" do
    expect(build(:user)).to be_valid
  end
end
