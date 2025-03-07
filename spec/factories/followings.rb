# spec/factories/followings.rb

# Define a sequence for unique user naming
FactoryBot.define do
  sequence :user_sequence
end

# Define the Following factory
FactoryBot.define do
  factory :following do
    # Explicitly create unique users with a sequence
    follower { create(:user, name: "Follower #{generate(:user_sequence)}") }
    followed { create(:user, name: "Followed #{generate(:user_sequence)}") }
  end
end
