# app/services/sleep_records/filterable.rb
module SleepRecords
  module Filterable
    # This module provides sorting and pagination functionality for sleep record services
    # @requires options [Hash] with potential keys: :sort_by, :sort_direction, :page, :per_page

    protected

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
        # Get all records for proper sorting
        all_records = query.to_a

        # Sort records by duration
        sorted_records = all_records.sort_by do |record|
          # Handle nil durations by using infinity as placeholder
          duration = record.duration_minutes
          sort_direction == :asc ? (duration || Float::INFINITY) : (duration || -Float::INFINITY)
        end

        # Reverse if descending
        sorted_records.reverse! if sort_direction == :desc

        sorted_records
      else
        # For other fields, use standard sorting
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

    def prepare_pagination_data(records)
      total_count = records.is_a?(Array) ? records.size : records.count
      records = paginate_records(records)

      pagination_data = {
        current_page: page,
        total_pages: (total_count.to_f / per_page).ceil,
        total_count: total_count,
        per_page: per_page
      }

      [ records, pagination_data ]
    end
  end
end
