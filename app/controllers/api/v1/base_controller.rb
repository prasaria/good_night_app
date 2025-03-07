module Api
  module V1
    class BaseController < ApplicationController
      # Set default format
      before_action :set_default_format

      # Handle common exceptions for all API controllers - grouped by handler
      rescue_from ActiveRecord::RecordNotFound,
                  ActionController::RoutingError,
                  Exceptions::NotFoundError,
                  with: :not_found

      rescue_from ActionController::ParameterMissing,
                  Exceptions::BadRequestError,
                  with: :bad_request

      rescue_from ActiveRecord::RecordInvalid,
                  Exceptions::UnprocessableEntityError,
                  with: :unprocessable_entity

      rescue_from Exceptions::ForbiddenError, with: :forbidden
      rescue_from Exceptions::UnauthorizedError, with: :unauthorized

      private

      def set_default_format
        request.format = :json
      end

      # Error response methods
      def not_found(exception)
        render json: {
          status: "error",
          message: "Not found",
          details: exception.message
        }, status: :not_found
      end

      def bad_request(exception)
        render json: {
          status: "error",
          message: "Bad request",
          details: exception.message
        }, status: :bad_request
      end

      def unprocessable_entity(exception)
        error_details = if exception.is_a?(ActiveRecord::RecordInvalid)
                          exception.record.errors.full_messages
        else
                          exception.message
        end

        render json: {
          status: "error",
          message: "Validation failed",
          details: error_details
        }, status: :unprocessable_entity
      end

      def forbidden(exception)
        render json: {
          status: "error",
          message: "Forbidden",
          details: exception.message
        }, status: :forbidden
      end

      def unauthorized(exception)
        render json: {
          status: "error",
          message: "Unauthorized",
          details: exception.message
        }, status: :unauthorized
      end

      # Helper for consistent success response format
      def render_success(data = {}, status = :ok, message = "Success")
        render json: {
          status: "success",
          message: message,
          data: data
        }, status: status
      end
    end
  end
end
