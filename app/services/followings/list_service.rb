# app/services/followings/list_service.rb
module Followings
  class ListService
    include Followings::Filterable

    attr_reader :user, :options

    def initialize(user:, **options)
      @user = user
      @options = options
    end

    def call
      # Validate user is present
      return ServiceResult.failure("User is required") if user.nil?

      # Get followed users query
      followed_users = build_query

      # Set up pagination metadata
      if paginated?
        followed_users, pagination_data = prepare_pagination_data(followed_users)
        ServiceResult.success(followed_users: followed_users, pagination: pagination_data)
      else
        # For non-paginated results, still include basic pagination info for consistency
        total_count = followed_users.is_a?(Array) ? followed_users.size : followed_users.count
        pagination_data = {
          total_count: total_count,
          current_page: 1,
          total_pages: (total_count > 0) ? 1 : 0,
          per_page: total_count
        }
        ServiceResult.success(followed_users: followed_users, pagination: pagination_data)
      end
    end

    private

    def build_query
      # Get base query of followed users
      query = user.followed_users

      # Apply sorting
      query = apply_sorting(query)

      query
    end

    def apply_sorting(query)
      sort_by = options[:sort_by]&.to_s || "name"
      sort_direction = options[:sort_direction]&.to_s == "desc" ? :desc : :asc

      case sort_by
      when "name"
        # Sort alphabetically by name
        query.order(name: sort_direction)
      when "recent"
        # Use a subquery approach to avoid duplicate joins
        user_ids_by_recent = user.followings.order(created_at: :desc).pluck(:followed_id)

        if user_ids_by_recent.empty?
          query # Return unmodified query if no followings
        else
          # Use case statement to order by position in the array
          order_clause = "CASE users.id "
          user_ids_by_recent.each_with_index do |id, index|
            order_clause += "WHEN #{id} THEN #{index} "
          end
          order_clause += "ELSE #{user_ids_by_recent.size} END"

          query.order(Arel.sql(order_clause))
        end
      else
        # Default to name sorting
        query.order(name: :asc)
      end
    end
  end
end
