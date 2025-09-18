class Staff < ApplicationRecord
  belongs_to :user
  belongs_to :practice

  has_many :appointments, foreign_key: :provider_id, disable_joins: true

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
end
