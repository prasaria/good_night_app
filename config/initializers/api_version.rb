# config/initializers/api_version.rb
module ApiVersion
  class Constraint
    def initialize(version)
      @version = version
    end

    def matches?(request)
      # If Accept header includes version, use it
      # Otherwise, default to requested version
      request.headers.fetch(:accept, "").include?("version=#{@version}") ||
        request.params[:version] == @version.to_s
    end
  end
end
