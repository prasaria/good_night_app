# db/seeds.rb

puts "Temporarily disabling overlap validation for seeding..."
SleepRecord.skip_overlap_validation = true

# Clear existing data to avoid duplicates when re-seeding
puts "Cleaning database..."
Following.destroy_all
SleepRecord.destroy_all
User.destroy_all

# Create Users
puts "Creating users..."

# Create a set of demo users
demo_users = [
  { name: "Alice Johnson" },
  { name: "Bob Smith" },
  { name: "Charlie Davis" },
  { name: "Diana Miller" },
  { name: "Ethan Brown" },
  { name: "Fiona Wilson" },
  { name: "George Thompson" },
  { name: "Hannah Moore" },
  { name: "Ian Wright" },
  { name: "Julia Taylor" }
]

created_users = demo_users.map { |user_attrs| User.create!(user_attrs) }

puts "Created #{created_users.size} users"

# Create Following relationships
puts "Creating following relationships..."
follow_count = 0

# Each user follows multiple others (but not themselves)
created_users.each do |user|
  # Generate a random number of users to follow (2-5)
  users_to_follow = created_users.reject { |u| u == user }.sample(rand(2..5))

  users_to_follow.each do |followed_user|
    Following.create!(follower: user, followed: followed_user)
    follow_count += 1
  end
end

puts "Created #{follow_count} following relationships"

# Create Sleep Records (SIMPLIFIED APPROACH)
puts "Creating sleep records..."
sleep_record_count = 0

# We'll assign specific dates for each user
created_users.each_with_index do |user, user_index|
  puts "Creating sleep records for user: #{user.name}"

  # Create 5-10 sequential sleep records for each user
  num_records = rand(5..10)

  # Each user gets a completely separate block of days
  # First user gets days 60-50 ago, second gets 49-40 ago, etc.
  base_day = 60 - (user_index * 10)

  num_records.times do |i|
    # Each record is on a different day within that user's range
    days_ago = base_day - i
    day_start = days_ago.days.ago.beginning_of_day

    # Set random bedtime between 9pm and midnight
    sleep_start = day_start.change(hour: rand(21..23), min: rand(0..59))

    # Sleep between 5-9 hours
    sleep_hours = rand(5..9)
    sleep_end = sleep_start + sleep_hours.hours

    SleepRecord.create!(
      user: user,
      start_time: sleep_start,
      end_time: sleep_end,
      duration_minutes: sleep_hours * 60
    )

    sleep_record_count += 1
  end
end

puts "Created #{sleep_record_count} sleep records"

# Create special data for demonstrations
puts "Creating demonstration data..."

# Get our demo users for specific examples
alice = User.find_by(name: "Alice Johnson")
bob = User.find_by(name: "Bob Smith")
charlie = User.find_by(name: "Charlie Davis")

# Ensure Alice, Bob, and Charlie follow each other
[ alice, bob, charlie ].permutation(2).each do |follower, followed|
  Following.find_or_create_by!(follower: follower, followed: followed)
end

# Clear any existing sleep records for Alice, Bob, and Charlie
SleepRecord.where(user: [ alice, bob, charlie ]).destroy_all

# Create sleep records for last 7 days
puts "Creating sleep records for demo users (Alice, Bob, Charlie)"

# Alice: consistent sleep schedule (7 days ago to yesterday)
7.downto(1) do |days_ago|
  day = days_ago.days.ago.beginning_of_day

  SleepRecord.create!(
    user: alice,
    start_time: day.change(hour: 22, min: rand(0..30)),
    end_time: (day + 1.day).change(hour: 6, min: rand(0..30)),
    duration_minutes: 8 * 60
  )

  puts "  Created sleep record for Alice on #{day.to_date}"
end

# Bob: variable sleep schedule (7 days ago to yesterday)
7.downto(1) do |days_ago|
  day = days_ago.days.ago.beginning_of_day
  hours = days_ago.even? ? rand(7..8) : rand(5..6)

  SleepRecord.create!(
    user: bob,
    start_time: day.change(hour: rand(21..23), min: rand(0..59)),
    end_time: (day + 1.day).change(hour: rand(5..7), min: rand(0..59)),
    duration_minutes: hours * 60
  )

  puts "  Created sleep record for Bob on #{day.to_date}"
end

# Charlie: only specific days (1, 3, 4, 6 days ago)
charlie_days = [ 1, 3, 4, 6 ]
charlie_days.each do |days_ago|
  day = days_ago.days.ago.beginning_of_day

  SleepRecord.create!(
    user: charlie,
    start_time: day.change(hour: 23, min: rand(0..59)),
    end_time: (day + 1.day).change(hour: 7, min: rand(0..59)),
    duration_minutes: 8 * 60
  )

  puts "  Created sleep record for Charlie on #{day.to_date}"
end

# Add a CURRENT in-progress sleep session for Charlie
now = Time.current
if now.hour >= 21 || now.hour < 7
  # It's nighttime, so create an in-progress sleep record
  SleepRecord.create!(
    user: charlie,
    start_time: now - 1.hour, # Started 1 hour ago
    end_time: nil,
    duration_minutes: nil
  )
  puts "  Created in-progress sleep record for Charlie (started 1 hour ago)"
else
  # It's daytime, so create a record from last night that's still in progress
  last_night = now.beginning_of_day.change(hour: 23, min: 0)
  SleepRecord.create!(
    user: charlie,
    start_time: last_night,
    end_time: nil,
    duration_minutes: nil
  )
  puts "  Created in-progress sleep record for Charlie (started last night)"
end

# Re-enable validation for normal application operation
SleepRecord.skip_overlap_validation = false
puts "Re-enabled overlap validation for normal operation"

puts "Seeding completed successfully!"
