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
    status_code = determine_status_code(error)
    error_response = build_error_response(error, status_code, env)

    headers = { "Content-Type" => "application/json" }
    body = [ error_response.to_json ]

    [ status_code, headers, body ]
  end

  def determine_status_code(error)
    if error.respond_to?(:http_status)
      error.http_status
    else
      case error
      when ActiveRecord::RecordNotFound, ActionController::RoutingError
        404
      when ActionController::ParameterMissing
        400
      when ActiveRecord::RecordInvalid
        422
      else
        500
      end
    end
  end

  def build_error_response(error, status_code, env)
    response = {
      status: "error",
      message: status_message(status_code),
      details: error.message
    }

    # Add error_code if available
    response[:error_code] = error.error_code if error.respond_to?(:error_code)

    # Add debugging information in development
    if Rails.env.development? || Rails.env.test?
      response[:backtrace] = error.backtrace&.first(10)
      response[:error_class] = error.class.name

      # Add request details
      response[:request] = {
        path: env["PATH_INFO"],
        method: env["REQUEST_METHOD"],
        query: env["QUERY_STRING"],
        format: env["HTTP_ACCEPT"]
      }
    end

    response
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
