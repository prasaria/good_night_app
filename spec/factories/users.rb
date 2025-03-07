# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    name { Faker::Name.name }

    # Add trait for a user with sleep records
    trait :with_sleep_records do
      after(:create) do |user|
        create_list(:sleep_record, 3, user: user)
      end
    end

    # Add trait for a user with followers
    trait :with_followers do
      after(:create) do |user|
        create_list(:following, 2, followed: user)
      end
    end

    # Add trait for a user following others
    trait :following_others do
      after(:create) do |user|
        create_list(:following, 2, follower: user)
      end
    end
  end
end
