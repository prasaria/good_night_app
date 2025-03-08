# app/services/sleep_records/retrieval_service.rb
module SleepRecords
  class RetrievalService
    include SleepRecords::Filterable

    attr_reader :user, :options

    def initialize(user:, **options)
      @user = user
      @options = options
    end

    def call
      # Validate user is present
      raise Exceptions::BadRequestError, "User is required" if user.nil?

      # Build query
      records = build_query

      # Process and return results
      if paginated?
        records, pagination_data = prepare_pagination_data(records)
        {
          records: records,
          page: pagination_data[:current_page],
          total_pages: pagination_data[:total_pages],
          pagination: pagination_data
        }
      else
        { records: records }
      end
    end

    private

    def build_query
      query = user.sleep_records

      # Filter by completion status
      if options[:completed_only]
        query = query.completed
      elsif options[:in_progress_only]
        query = query.in_progress
      end

      # Filter by date range
      if options[:from_last_week]
        query = query.from_last_week
      else
        query = query.where("start_time >= ?", options[:start_date]) if options[:start_date]
        query = query.where("start_time <= ?", options[:end_date]) if options[:end_date]
      end

      # Sort records
      query = apply_sorting(query)

      # Limit results if requested
      query = query.limit(options[:limit]) if options[:limit] && !paginated?

      query
    end
  end
end
