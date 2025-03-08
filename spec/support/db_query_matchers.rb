# spec/support/db_query_matchers.rb
require 'db-query-matchers'

RSpec.configure do |config|
  config.before(:suite) do
    # Ignore PostgreSQL system queries
    DBQueryMatchers.configure do |config|
      config.ignores = [ /SHOW/ ]
    end
  end
end
