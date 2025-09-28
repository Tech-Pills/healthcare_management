class Appointment < ApplicationRecord
  belongs_to :patient, dependent: :destroy
  belongs_to :provider, class_name: "Staff"

  has_many :medical_records, dependent: :destroy

  validates :practice_id, presence: true
  validates :scheduled_at, presence: true
  validates :duration_minutes, numericality: { only_integer: true, greater_than: 0 }

  after_create :schedule_reminders

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

  def schedule_reminders
    AppointmentReminderScheduler.new(self).schedule_reminders
  end
end
