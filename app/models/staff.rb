class Staff < ApplicationRecord
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

  def practice
    return nil unless practice_id
    @practice ||= Practice.find_by(id: practice_id)
  end

  def user
    return nil unless user_id
    @user ||= User.find_by(id: user_id)
  end
end
