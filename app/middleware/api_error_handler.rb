# app/middleware/api_error_handler.rb
class ApiErrorHandler
  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  rescue => error
    if api_request?(env)
      handle_api_error(error, env)
    else
      raise error
    end
  end

  private

  def api_request?(env)
    path = env["PATH_INFO"]
    path.start_with?("/api")
  end

  def handle_api_error(error, env)
    status_code = error_status_code(error)

    error_response = {
      status: "error",
      message: status_message(status_code),
      details: error.message
    }

    # Add backtrace in development for debugging
    if Rails.env.development? || Rails.env.test?
      error_response[:backtrace] = error.backtrace&.first(10)
      error_response[:error_class] = error.class.name

      # Add request details
      request_info = {
        path: env["PATH_INFO"],
        method: env["REQUEST_METHOD"],
        query: env["QUERY_STRING"],
        format: env["HTTP_ACCEPT"]
      }
      error_response[:request] = request_info
    end

    headers = { "Content-Type" => "application/json" }
    body = [ error_response.to_json ]

    [ status_code, headers, body ]
  end

  def error_status_code(error)
    case error
    when ActiveRecord::RecordNotFound, ActionController::RoutingError
      404
    when ActionController::ParameterMissing
      400
    when ActiveRecord::RecordInvalid
      422
    when Exceptions::ForbiddenError
      403
    else
      500
    end
  end

  def status_message(status_code)
    {
      400 => "Bad Request",
      401 => "Unauthorized",
      403 => "Forbidden",
      404 => "Not Found",
      422 => "Unprocessable Entity",
      500 => "Internal Server Error"
    }[status_code] || "Error"
  end
end
