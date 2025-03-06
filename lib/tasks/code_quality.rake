namespace :code_quality do
  desc "Run all code quality checks"
  task all: [ :rubocop, :brakeman, :bundle_audit, :erb_lint ]

  desc "Run RuboCop"
  task :rubocop do
    puts "Running RuboCop..."
    system "bundle exec rubocop -A"
  end

  desc "Run Brakeman security scan"
  task :brakeman do
    puts "Running Brakeman security scan..."
    system "bundle exec brakeman -q"
  end

  desc "Run Bundler Audit"
  task :bundle_audit do
    puts "Running Bundler Audit..."
    system "bundle exec bundle-audit check --update"
  end

  desc "Run ERB Lint"
  task :erb_lint do
    puts "Running ERB Lint..."
    system "bundle exec erb_lint --lint-all"
  end

  desc "Fix auto-correctable issues"
  task :fix do
    puts "Auto-correcting RuboCop offenses..."
    system "bundle exec rubocop -A"
    puts "Auto-correcting ERB Lint offenses..."
    system "bundle exec erb_lint --lint-all --autocorrect"
  end
end

# Run code quality checks before tests if in CI environment
if ENV["CI"]
task spec: [ "code_quality:all" ]
end
