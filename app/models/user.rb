class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  delegate :full_name, :role, :active?, to: :staff, allow_nil: true

  def staff?
    staff.present?
  end

  def staff
    return nil unless ApplicationRecord.current_tenant
    @staff ||= ApplicationRecord.with_tenant(ApplicationRecord.current_tenant) do
      Staff.find_by(user_id: id)
    end
  end

  def practice
    return nil unless ApplicationRecord.current_tenant
    @practice ||= Practice.find_by(slug: ApplicationRecord.current_tenant)
  end
end
