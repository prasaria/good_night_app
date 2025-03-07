# spec/factories/sleep_records.rb
FactoryBot.define do
  factory :sleep_record do
    user
    sequence(:start_time) { |n| n.days.ago } # Each record gets a different start time
    end_time { nil }
    duration_minutes { nil }

    trait :completed do
      end_time { start_time + 8.hours }
      duration_minutes { 8 * 60 } # 8 hours in minutes
    end

    trait :last_week do
      start_time { 1.week.ago }
      end_time { 1.week.ago + 8.hours }
      duration_minutes { 8 * 60 } # 8 hours in minutes
    end
  end
end
