class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  has_one :staff
  has_one :practice, through: :staff, disable_joins: true

  delegate :full_name, :role, :active?, to: :staff, allow_nil: true

  def staff?
    staff.present?
  end
end
