# app/controllers/api/v1/health_controller.rb
module Api
  module V1
    class HealthController < BaseController
      def check
        render_success({ status: "healthy", version: "1.0" })
      end
    end
  end
end
