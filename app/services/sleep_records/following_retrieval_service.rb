# app/services/sleep_records/following_retrieval_service.rb
module SleepRecords
  class FollowingRetrievalService
    include SleepRecords::Filterable

    attr_reader :user, :options

    def initialize(user:, **options)
      @user = user
      @options = options
    end

    def call
      # Validate user is present
      return ServiceResult.failure("User is required") if user.nil?

      # Build query
      records = build_query

      # Paginate if requested
      if paginated?
        records, pagination_data = prepare_pagination_data(records)
        ServiceResult.success(records: records, pagination: pagination_data)
      else
        ServiceResult.success(records: records)
      end
    end

    private

    def build_query
      # Get IDs of followed users
      followed_user_ids = if options[:followed_user_ids].present?
                            # Filter to ensure we only include actual followed users
                            (user.followed_user_ids & Array(options[:followed_user_ids]))
      else
                            user.followed_user_ids
      end

      # Return early if user follows no one
      return [] if followed_user_ids.empty?

      # Get sleep records for followed users
      query = SleepRecord.where(user_id: followed_user_ids)

      # Filter by completion status
      if options[:completed_only]
        query = query.completed
      elsif options[:in_progress_only]
        query = query.in_progress
      end

      # Filter by date range
      if options[:from_last_week]
        query = query.from_last_week
      elsif options[:start_date] || options[:end_date]
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
