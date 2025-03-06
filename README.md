# Good Night App

A Rails 8 API for tracking sleep patterns and following other users.

## Project Overview

This application provides a REST API for users to track their sleep schedules and connect with others. Built with Ruby 3.3.4 and Rails 8, it demonstrates modern API development practices with a focus on performance, scalability, and code quality.

## Features

- **Sleep Tracking**
  - Clock in when going to bed
  - Clock out when waking up
  - View personal sleep records sorted by creation time

- **Social Connection**
  - Follow other users
  - Unfollow users
  - View list of followed users

- **Social Sleep Analysis**
  - View sleep records of followed users
  - Filter to the previous week
  - Sort by sleep duration
  - Chronological presentation of all records

## Technical Requirements

- Ruby 3.3.4
- Rails 8
- PostgreSQL 16
- Docker & Docker Compose (for containerized development)
- 90%+ test coverage

## Getting Started

### Prerequisites

Ensure you have the following installed:

- Docker and Docker Compose
- Git

### Setup

1. Clone the repository:

   ```bash
   git clone git@github.com:prasaria/good_night_app.git
   cd good_night_app
   ```

2. Start the Docker environment:

   ```bash
   docker-compose up
   ```

3. Access the API at `http://localhost:3000`

### Database Setup

The database will be automatically set up when you start the Docker environment. If you need to run migrations manually:

```bash
docker-compose exec web rails db:migrate
```

To reset the database:

```bash
docker-compose exec web rails db:reset
```

## Development

### Running the Rails Console

```bash
docker-compose exec web rails console
```

### Running Tests

```bash
docker-compose exec web bundle exec rspec
```

View test coverage reports in the `coverage` directory after running tests.

### Database Operations

```bash
# Run migrations
docker-compose exec web rails db:migrate

# Rollback last migration
docker-compose exec web rails db:rollback

# Rollback multiple migrations
docker-compose exec web rails db:rollback STEP=3

# Seed the database
docker-compose exec web rails db:seed
```

### Code Quality

This project uses several code quality tools:

```bash
# Run RuboCop
docker-compose exec web bundle exec rubocop

# Run Brakeman security scan
docker-compose exec web bundle exec brakeman

# Run all code quality checks
docker-compose exec web bundle exec rake code_quality:all

# Auto-fix issues where possible
docker-compose exec web bundle exec rubocop -A
```

## API Endpoints

### Sleep Records

- `POST /api/v1/sleep_records/start` - Mark sleep start time
- `PATCH /api/v1/sleep_records/:id/end` - Mark sleep end time
- `GET /api/v1/sleep_records` - Get current user's sleep records

### Following System

- `POST /api/v1/followings` - Follow a user
- `DELETE /api/v1/followings/:id` - Unfollow a user
- `GET /api/v1/followings` - Get list of users the current user follows

### Following Sleep Records

- `GET /api/v1/followings/sleep_records` - Get sleep records of followed users

## Scalability Strategies

This application is designed to handle high data volumes and concurrent requests through:

- Optimized database indexing
- Connection pooling
- Caching with Redis
- API pagination
- Fiber-based concurrency for I/O operations
- Efficient query optimization

## Testing

The project maintains high test coverage using:

- RSpec for test framework
- FactoryBot for test data generation
- SimpleCov for coverage reporting
- Database Cleaner for test isolation

Run the full test suite with:

```bash
docker-compose exec web bundle exec rspec
```

## CI/CD Pipeline

The GitHub Actions CI pipeline runs:

1. Security scanning (Brakeman)
2. Code linting (RuboCop)
3. Test suite with coverage verification
4. Docker image builds

## Project Structure

This project follows a modular, service-oriented architecture inspired by Spree Commerce:

- Controllers handle HTTP request/response cycle
- Service objects encapsulate business logic
- Serializers format API responses
- Comprehensive test suite

## License

This project is using MIT license

## Acknowledgments

- Built with Ruby on Rails 8
- PostgreSQL for reliable data storage
- Docker for consistent development environments
