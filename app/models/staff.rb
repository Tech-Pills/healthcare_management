class Staff < ApplicationRecord
  belongs_to :user
  has_many :appointments, foreign_key: :provider_id, dependent: :destroy

  validates :practice_id, presence: true

  enum :role, {
    admin: "admin",
    doctor: "doctor",
    nurse: "nurse",
    receptionist: "receptionist",
    lab_tech: "lab_tech",
    manager: "manager"
  }

  def medical_staff?
    doctor? || nurse?
  end

  def can_manage_practice?
    admin? || manager?
  end

  def full_name
    [ first_name, last_name ].compact.join(" ")
  end

  def practice
    return nil unless practice_id
    @practice ||= Practice.find_by(id: practice_id)
  end
end
