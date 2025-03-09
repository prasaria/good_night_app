# app/controllers/api/v1/health_controller.rb
module Api
  module V1
    class HealthController < BaseController
      def check
        render_success({ status: "healthy", version: "1.0" })
      end

      def redis
        begin
          test_key = "health_check_redis_#{Time.zone.now.to_i}"
          test_value = "test_value_#{rand(1000)}"

          start_time = Time.zone.now
          Rails.cache.write(test_key, test_value, expires_in: 10.seconds)
          read_value = Rails.cache.read(test_key)
          duration_ms = ((Time.zone.now - start_time) * 1000).round(2)

          # Clean up
          Rails.cache.delete(test_key)

          if read_value == test_value
            render json: {
              status: "ok",
              message: "Redis cache is working correctly",
              response_time_ms: duration_ms
            }
          else
            render json: {
              status: "error",
              message: "Redis cache read/write mismatch",
              wrote: test_value,
              read: read_value,
              response_time_ms: duration_ms
            }, status: :service_unavailable
          end
        rescue => e
          render json: {
            status: "error",
            message: "Redis cache test failed: #{e.message}",
            error: e.class.name
          }, status: :service_unavailable
        end
      end
    end
  end
end
