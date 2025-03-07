# app/services/followings/filterable.rb
module Followings
  module Filterable
    protected

    def paginated?
      options[:page].present?
    end

    def page
      [ options[:page].to_i, 1 ].max
    end

    def per_page
      options[:per_page].present? ? [ options[:per_page].to_i, 1 ].max : 10
    end

    def prepare_pagination_data(records)
      total_count = records.is_a?(Array) ? records.size : records.count
      records = paginate_records(records)

      pagination_data = {
        current_page: page,
        total_pages: [ 1, (total_count.to_f / per_page).ceil ].max,
        total_count: total_count,
        per_page: per_page,
        is_last_page: page >= [ (total_count.to_f / per_page).ceil, 1 ].max
      }

      [ records, pagination_data ]
    end

    def paginate_records(records)
      # If records is already an Array, paginate manually
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
