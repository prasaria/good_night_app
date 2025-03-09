# app/models/following.rb
class Following < ApplicationRecord
  # Associations
  belongs_to :follower, class_name: "User"
  belongs_to :followed, class_name: "User"

  # Validations
  validates :follower_id, uniqueness: { scope: :followed_id }
  validate :not_follow_self

  # Callbacks
  after_save :invalidate_caches
  after_destroy :invalidate_caches

  private

  def not_follow_self
    if follower_id == followed_id
      errors.add(:followed_id, "can't follow yourself")
    end
  end

  def invalidate_caches
    # Invalidate follower's followed users cache
    Rails.cache.delete_matched("followings/user_#{follower_id}/*") rescue nil

    # Invalidate follower's followed users' sleep records cache
    Rails.cache.delete_matched("sleep_record_following/user_#{follower_id}/*") rescue nil
  end
end
