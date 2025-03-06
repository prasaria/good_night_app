# config/initializers/strong_migrations.rb
StrongMigrations.start_after = 20230101000000  # Set to current timestamp

StrongMigrations.auto_analyze = true

# Configure warnings
StrongMigrations.enable_check(:add_index)
StrongMigrations.enable_check(:add_reference)
StrongMigrations.enable_check(:add_column_default)
StrongMigrations.enable_check(:change_column_null)
