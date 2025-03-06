#!/bin/bash
set -e

# If bundle check fails, run bundle install
bundle check || bundle install

# Remove a potentially pre-existing server.pid for Rails.
rm -f /rails/tmp/pids/server.pid

# Execute the command passed as arguments
exec "$@"
