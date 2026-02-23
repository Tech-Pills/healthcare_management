class Staff < ApplicationRecord
  belongs_to :practice, optional: true
  belongs_to :user, optional: true

  has_many :appointments, foreign_key: :provider_id, dependent: :destroy

  validates :practice_id, presence: true
  validates :user_id, presence: true

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
