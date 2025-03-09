# config/initializers/redis.rb
require "redis"

# Set up a global Redis client for non-cache operations (if needed)
$redis = Redis.new(
  url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
  timeout: 1
)

# Explicitly log connection status in development to log file
if Rails.env.development?
  File.open(Rails.root.join("log", "redis_connection.log"), "a") do |f|
    f.puts "#{Time.zone.now} - Redis connection status: #{$redis.ping rescue 'ERROR: ' + $!.message}"
  end
end
