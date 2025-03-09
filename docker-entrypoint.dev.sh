#!/bin/bash
set -e

# Install dependencies
echo "Checking bundle installation..."
bundle check || bundle install

# Remove server.pid if it exists
rm -f /rails/tmp/pids/server.pid

# Wait for database
echo "Waiting for PostgreSQL..."
while ! pg_isready -h db -U postgres > /dev/null 2>&1; do
  sleep 1
done

# Setup database
echo "Setting up database..."
if bundle exec rails db:exists 2>/dev/null; then
  echo "Database exists, running migrations..."
  bundle exec rails db:migrate
else
  echo "Database doesn't exist, creating and seeding..."
  bundle exec rails db:prepare db:seed
fi

# Create cache directory and enable caching in Docker
if [ "$DOCKER_ENV" = "true" ] && [ "$RAILS_ENV" = "development" ]; then
  mkdir -p /rails/tmp
  touch /rails/tmp/caching-dev.txt
  echo "Enabled caching for Docker development environment"
fi

# Execute the main command
echo "Starting application..."
exec "$@"
