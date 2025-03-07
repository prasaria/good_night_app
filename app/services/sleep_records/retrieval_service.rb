# app/services/sleep_records/retrieval_service.rb
module SleepRecords
  class RetrievalService
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
        total_count = records.is_a?(Array) ? records.size : records.count
        records = paginate_records(records)

        pagination_data = {
          current_page: page,
          total_pages: (total_count.to_f / per_page).ceil,
          total_count: total_count,
          per_page: per_page
        }

        ServiceResult.success(records: records, page: page, total_pages: pagination_data[:total_pages], pagination: pagination_data)
      else
        ServiceResult.success(records: records)
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

    def apply_sorting(query)
      # Normalize sort_by
      sort_by_param = options[:sort_by]&.to_s
      sort_by = case sort_by_param
      when "duration" then :duration_minutes
      when "start_time", "end_time", "created_at" then sort_by_param.to_sym
      else :created_at
      end

      sort_direction = (options[:sort_direction]&.to_sym || :desc)
      valid_sort_directions = [ :asc, :desc ]
      sort_direction = :desc unless valid_sort_directions.include?(sort_direction)

      # Handle special case for sorting by duration
      if sort_by == :duration_minutes
        # For SQLite and PostgreSQL
        direction_str = sort_direction == :asc ? "ASC" : "DESC"
        nulls_str = sort_direction == :asc ? "NULLS LAST" : "NULLS FIRST"

        # Try database-specific sorting first
        begin
          query.order(Arel.sql("duration_minutes #{direction_str} #{nulls_str}"))
        rescue ActiveRecord::StatementInvalid
          # Fall back to Ruby sorting if database doesn't support NULLS FIRST/LAST
          records = query.to_a

          # Sort records by duration
          sorted_records = records.sort_by do |record|
            # Use infinity values to handle nil durations properly
            duration = record.duration_minutes
            sort_direction == :asc ? (duration || Float::INFINITY) : (duration || -Float::INFINITY)
          end

          # Reverse if descending
          sorted_records.reverse! if sort_direction == :desc

          sorted_records
        end
      else
        # For other fields, normal sorting
        query.order(sort_by => sort_direction)
      end
    end

    def paginated?
      options[:page].present?
    end

    def page
      [ options[:page].to_i, 1 ].max
    end

    def per_page
      options[:per_page].present? ? [ options[:per_page].to_i, 1 ].max : 10
    end

    def paginate_records(records)
      # If records is already an Array (from duration sorting), paginate manually
      if records.is_a?(Array)
        start_index = (page - 1) * per_page
        records[start_index, per_page] || []
      else
        # Use ActiveRecord's pagination
        records.offset((page - 1) * per_page).limit(per_page)
      end
    end
  end
end
