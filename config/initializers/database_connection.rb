# config/initializers/database_connection.rb
Rails.application.config.after_initialize do
  ActiveRecord::Base.connection_pool.disconnect! if ActiveRecord::Base.connected?

  # Set pool size based on ENV variable or default to 5
  ActiveRecord::Base.establish_connection(
    Rails.application.config.database_configuration[Rails.env]
    .merge(pool: ENV.fetch("RAILS_MAX_THREADS") { 5 }.to_i)
  )
end
