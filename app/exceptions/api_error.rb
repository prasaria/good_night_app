# app/exceptions/api_errors.rb
module Exceptions
  class ApiError < StandardError
    attr_reader :http_status, :error_code

    def initialize(message, http_status, error_code = nil)
      @http_status = http_status
      @error_code = error_code || self.class.name.demodulize.underscore
      super(message)
    end
  end

  class BadRequestError < ApiError
    def initialize(message = "Bad request", error_code = nil)
      super(message, 400, error_code)
    end
  end

  class UnauthorizedError < ApiError
    def initialize(message = "Authentication required", error_code = nil)
      super(message, 401, error_code)
    end
  end

  class ForbiddenError < ApiError
    def initialize(message = "You don't have permission to access this resource", error_code = nil)
      super(message, 403, error_code)
    end
  end

  class NotFoundError < ApiError
    def initialize(message = "Resource not found", error_code = nil)
      super(message, 404, error_code)
    end
  end

  class UnprocessableEntityError < ApiError
    def initialize(message = "Validation failed", error_code = nil)
      super(message, 422, error_code)
    end
  end

  class InternalServerError < ApiError
    def initialize(message = "Internal server error", error_code = nil)
      super(message, 500, error_code)
    end
  end
end
