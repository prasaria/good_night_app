# app/exceptions/forbidden_error.rb
module Exceptions
  class ForbiddenError < StandardError
    def initialize(message = "You don't have permission to access this resource")
      super(message)
    end
  end
end
