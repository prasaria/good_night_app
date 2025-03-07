# app/services/service_result.rb
class ServiceResult
  attr_reader :success, :errors, :data

  def initialize(success:, errors: [], **data)
    @success = success
    @errors = Array(errors)
    @data = data
  end

  def success?
    @success
  end

  def method_missing(method_name, *args, &block)
    if data.key?(method_name)
      data[method_name]
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    data.key?(method_name) || super
  end

  class << self
    def success(**data)
      new(success: true, **data)
    end

    def failure(errors, **data)
      new(success: false, errors: errors, **data)
    end
  end
end
