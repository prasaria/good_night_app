# config/initializers/redis.rb
require "redis"

# Set up a global Redis client for non-cache operations (if needed)
$redis = Redis.new(
  url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
  timeout: 1
)

# Log connection status in development
if Rails.env.development?
  begin
    $redis.ping
    Rails.logger.info "Redis connected successfully at #{ENV.fetch('REDIS_URL', 'redis://localhost:6379/0')}"
  rescue Redis::CannotConnectError => e
    Rails.logger.error "Failed to connect to Redis: #{e.message}"
  end
end
