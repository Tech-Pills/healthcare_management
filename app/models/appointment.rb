class Appointment < ApplicationRecord
  belongs_to :provider, class_name: "Staff"

  validates :practice_id, presence: true
  validates :patient_id, presence: true

  validates :scheduled_at, presence: true
  validates :duration_minutes, numericality: { only_integer: true, greater_than: 0 }

  enum :status, {
    scheduled: "scheduled",
    completed: "completed",
    canceled: "canceled",
    no_show: "no_show"
  }
end
