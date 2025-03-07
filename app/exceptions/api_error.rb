# app/exceptions/api_errors.rb
module Exceptions
  class BadRequestError < StandardError
    def initialize(message = "Bad request")
      super(message)
    end
  end

  class UnauthorizedError < StandardError
    def initialize(message = "Authentication required")
      super(message)
    end
  end

  class ForbiddenError < StandardError
    def initialize(message = "You don't have permission to access this resource")
      super(message)
    end
  end

  class NotFoundError < StandardError
    def initialize(message = "Resource not found")
      super(message)
    end
  end

  class UnprocessableEntityError < StandardError
    def initialize(message = "Validation failed")
      super(message)
    end
  end
end
