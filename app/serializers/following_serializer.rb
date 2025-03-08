# app/serializers/following_serializer.rb
class FollowingSerializer
  def initialize(following, options = {})
    @following = following
    @options = options
  end

  def as_json
    {
      id: @following.id,
      follower_id: @following.follower_id,
      followed_id: @following.followed_id,
      created_at: @following.created_at,
      updated_at: @following.updated_at
    }.tap do |json|
      # Include follower/followed user data if explicitly requested
      if @options[:include_users]
        json[:follower] = UserSerializer.new(@following.follower).as_json if @following.follower
        json[:followed] = UserSerializer.new(@following.followed).as_json if @following.followed
      end
    end
  end

  # Class method to handle bulk serialization to avoid N+1 queries
  def self.serialize_collection(followings, options = {})
    # If we're including user data, we should preload the associations
    if options[:include_users]
      followings = followings.includes(:follower, :followed) unless followings.is_a?(Array)
    end

    followings.map { |following| new(following, options).as_json }
  end
end
