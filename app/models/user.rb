# app/models/user.rb
class User < ApplicationRecord
  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }

  # Associations
  has_many :sleep_records, dependent: :destroy

  has_many :followings, foreign_key: "follower_id", dependent: :destroy
  has_many :followed_users, through: :followings, source: :followed

  has_many :reverse_followings, class_name: "Following", foreign_key: "followed_id", dependent: :destroy
  has_many :followers, through: :reverse_followings, source: :follower

  # Methods for managing following relationships
  def follow(other_user)
    # Don't allow following self or duplicate followings
    return if self == other_user || following?(other_user)

    followings.create(followed: other_user)
  end

  def unfollow(other_user)
    followings.find_by(followed: other_user)&.destroy
  end

  def following?(other_user)
    followed_users.include?(other_user)
  end

  # Method to retrieve recent sleep records
  def recent_sleep_records(limit: nil)
    sleep_records.order(created_at: :desc).limit(limit)
  end
end
