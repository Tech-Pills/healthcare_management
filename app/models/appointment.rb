class Appointment < ApplicationRecord
  belongs_to :patient, dependent: :destroy
  belongs_to :provider, class_name: "Staff"

  validates :practice_id, presence: true
  validates :scheduled_at, presence: true
  validates :duration_minutes, numericality: { only_integer: true, greater_than: 0 }

  after_create :schedule_reminder_jobs
  after_update :schedule_reminder_jobs, if: :scheduled_at_changed?

  enum :status, {
    scheduled: "scheduled",
    completed: "completed",
    canceled: "canceled",
    no_show: "no_show"
  }

  def practice
    return nil unless practice_id
    @practice ||= Practice.find_by(id: practice_id)
  end

  private

  def schedule_reminder_jobs
    return unless scheduled_at.present?

    if scheduled_at > 24.hours.from_now
      AppointmentReminderJob
        .set(wait_until: scheduled_at - 24.hours)
        .perform_later(id, "24_hours")
    end

    if scheduled_at > 2.hours.from_now
      AppointmentReminderJob
        .set(wait_until: scheduled_at - 2.hours)
        .perform_later(id, "2_hours")
    end
  end
end
