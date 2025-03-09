# app/helpers/cache_helper.rb
module CacheHelper
  # Generate a cache key for a collection with pagination and filtering
  def collection_cache_key(collection_name, user_id, params = {})
    # Extract cache-relevant parameters - fix for ActionController::Parameters
    if params.is_a?(ActionController::Parameters)
      # Create a hash with only the keys we want, safely
      cache_params = {}
      [
        :page, :per_page, :sort_by, :sort_direction,
        :start_date, :end_date, :from_last_week,
        :completed_only, :in_progress_only, :limit,
        :followed_user_ids
      ].each do |key|
        cache_params[key] = params[key] if params.key?(key)
      end
    else
      # When params is a regular hash
      cache_params = params.slice(
        :page, :per_page, :sort_by, :sort_direction,
        :start_date, :end_date, :from_last_week,
        :completed_only, :in_progress_only, :limit,
        :followed_user_ids
      )
    end

    # Add collection etag based on latest update time
    begin
      collection_class = collection_name.to_s.classify.constantize

      # If user_id is provided, scope by user
      if user_id
        if collection_name.to_s == "sleep_record"
          # Handle sleep records (direct ownership)
          latest_update = collection_class.where(user_id: user_id).maximum(:updated_at)
        elsif collection_name.to_s == "following"
          # Handle followings (user is the follower)
          latest_update = collection_class.where(follower_id: user_id).maximum(:updated_at)
        end
      else
        latest_update = collection_class.maximum(:updated_at)
      end
    rescue => _e
      # If something goes wrong, use timestamp
      latest_update = Time.current.to_i
    end

    # Create a digest of the parameters
    param_digest = Digest::MD5.hexdigest(cache_params.to_s)

    # Format the timestamp safely - fix for Rails 8 TimeWithZone
    timestamp_part = if latest_update.is_a?(ActiveSupport::TimeWithZone) || latest_update.is_a?(Time)
      # Use to_f or to_i to get a numeric representation
      latest_update.to_i
    else
      latest_update || "none"
    end

    # Build the cache key
    [
      collection_name.to_s.pluralize,
      "user_#{user_id}",
      "params_#{param_digest}",
      timestamp_part.to_s
    ].join("/")
  end

  # Enhanced fetch_cached_collection that's safer
  def fetch_cached_collection(cache_key, expires_in: 15.minutes)
    # Skip caching if disabled
    unless Rails.application.config.action_controller.perform_caching
      Rails.logger.info "Caching disabled, retrieving directly from database"
      return yield
    end

    # Try to use cache, but gracefully fallback if it fails
    begin
      # Add some debug logs
      Rails.logger.info "Attempting to fetch from cache key: #{cache_key}"

      result = Rails.cache.fetch(cache_key, expires_in: expires_in) do
        Rails.logger.info "CACHE MISS - retrieving from database for key: #{cache_key}"
        yield
      end

      Rails.logger.info "Cache operation completed for key: #{cache_key}"
      result
    rescue => e
      # Log the error but don't crash the request
      Rails.logger.error "Caching error: #{e.message}" if Rails.logger
      Rails.logger.error e.backtrace.join("\n") if Rails.logger
      yield
    end
  end
end
