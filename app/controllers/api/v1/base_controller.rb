# app/controllers/api/v1/base_controller.rb
module Api
  module V1
    class BaseController < ApplicationController
      # Set default format
      before_action :set_default_format

      private

      def set_default_format
        request.format = :json
      end

      # Helper for consistent success response format
      def render_success(data = {}, status = :ok, message = "Success")
        render json: {
          status: "success",
          message: message,
          data: data
        }, status: status
      end

      def render_error(errors, status = :bad_request)
        error_message = Array(errors).first || "An error occurred"

        # Map status symbols to exception classes
        exception_class = case status
        when :not_found
          Exceptions::NotFoundError
        when :bad_request
          Exceptions::BadRequestError
        when :unprocessable_entity
          Exceptions::UnprocessableEntityError
        when :forbidden
          Exceptions::ForbiddenError
        when :unauthorized
          Exceptions::UnauthorizedError
        else
          Exceptions::BadRequestError
        end

        raise exception_class.new(error_message)
      end
    end
  end
end
