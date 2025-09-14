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

  def practice
    return nil unless practice_id
    @practice ||= Practice.find_by(id: practice_id)
  end

  def patient
    return nil unless patient_id && ApplicationRecord.current_tenant
    @patient ||= PatientsRecord.with_tenant(ApplicationRecord.current_tenant) do
      Patient.find_by(id: patient_id)
    end
  end
end
