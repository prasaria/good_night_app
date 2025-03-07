# app/controllers/api/v1/base_controller.rb
module Api
  module V1
    class BaseController < ApplicationController
      # Set default format
      before_action :set_default_format

      # Handle common exceptions for all API controllers
      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActionController::ParameterMissing, with: :bad_request
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity

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
        render json: {
          status: "error",
          message: "Validation failed",
          details: exception.record.errors.full_messages
        }, status: :unprocessable_entity
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
