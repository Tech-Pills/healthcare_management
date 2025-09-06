class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_one :staff, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  delegate :practice, :full_name, :role, :active?, to: :staff, allow_nil: true

  def staff?
    staff.present?
  end
end
