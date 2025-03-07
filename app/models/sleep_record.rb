# app/models/sleep_record.rb
class SleepRecord < ApplicationRecord
  # Associations
  belongs_to :user

  # Validations
  validates :start_time, presence: true
  validate :end_time_after_start_time, if: -> { end_time.present? }
  validate :no_overlapping_records, if: -> { start_time.present? }

  # Scopes
  scope :completed, -> { where.not(end_time: nil) }
  scope :in_progress, -> { where(end_time: nil) }
  scope :for_user, ->(user_id) { where(user_id: user_id) }
  scope :recent, ->(limit = nil) { order(created_at: :desc).limit(limit) }
  scope :from_last_week, -> { where("start_time > ?", 1.week.ago.beginning_of_day) }

  # Callbacks
  before_save :calculate_duration, if: -> { end_time_changed? && end_time.present? }

  # Methods
  def complete?(end_time)
    self.end_time = end_time
    calculate_duration
    save
  end

  private

  def calculate_duration
    return unless start_time && end_time
    self.duration_minutes = ((end_time - start_time) / 60).to_i
  end

  def end_time_after_start_time
    return unless end_time.present? && start_time.present?

    if end_time <= start_time
      errors.add(:end_time, "must be after start time")
    end
  end

  def no_overlapping_records
    return unless user_id.present? && start_time.present?

    overlapping_record = user.sleep_records
                              .where.not(id: id) # Exclude current record when updating
                              .where("(start_time <= ? AND (end_time IS NULL OR end_time >= ?))",
                                start_time, start_time)
                              .exists?

    if overlapping_record
      errors.add(:start_time, "overlaps with another sleep record")
    end
  end
end
