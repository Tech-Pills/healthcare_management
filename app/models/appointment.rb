class Appointment < ApplicationRecord
  belongs_to :practice, optional: true
  belongs_to :patient, optional: true
  belongs_to :provider, class_name: "Staff"

  has_many :medical_records, dependent: :destroy

  validates :practice_id, presence: true
  validates :scheduled_at, presence: true
  validates :duration_minutes, numericality: { only_integer: true, greater_than: 0 }

  after_create :schedule_reminders
  after_create_commit :broadcast_appointment_created
  after_update_commit :broadcast_appointment_updated
  after_destroy_commit :broadcast_appointment_destroyed

  enum :status, {
    scheduled: "scheduled",
    completed: "completed",
    canceled: "canceled",
    no_show: "no_show"
  }

  private

  def schedule_reminders
    AppointmentReminderScheduler.new(self).schedule_reminders
  end

  def broadcast_appointment_created
    broadcast_appointment_change("created")
  end

  def broadcast_appointment_updated
    broadcast_appointment_change("updated")
  end

  def broadcast_appointment_destroyed
    broadcast_appointment_change("destroyed")
  end

  def broadcast_appointment_change(action)
    return unless practice && patient && provider

    payload = {
      action: action,
      appointment: {
        id: id,
        patient_name: patient.full_name,
        provider_name: provider.full_name,
        scheduled_at: scheduled_at.strftime("%B %d, %Y at %I:%M %p"),
        status: status,
        duration_minutes: duration_minutes
      }
    }

    Staff.where(practice_id: practice_id).find_each do |staff|
      AppointmentChannel.broadcast_to(staff, payload)
    end
  end
end
