# spec/support/request_spec_helper.rb
module RequestSpecHelper
  # Parse JSON response to Ruby hash
  def json
    JSON.parse(response.body)
  end

  # Helper to set request headers for API
  def api_headers
    {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
  end
end

RSpec.configure do |config|
  # Include the helper for request specs
  config.include RequestSpecHelper, type: :request
end
