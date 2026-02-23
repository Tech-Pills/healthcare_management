class Practice < GlobalRecord
  validates :name, presence: true
  validates :address, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true
  validates :license_number, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug
  after_create :setup_tenants, unless: -> { Rails.env.test? }
  before_destroy :cleanup_tenants, unless: -> { Rails.env.test? }

  has_many :staffs, class_name: "Staff", foreign_key: :practice_id
  has_many :patients, class_name: "Patient", foreign_key: :practice_id
  has_many :appointments, class_name: "Appointment", foreign_key: :practice_id
  has_many :users, through: :staffs

  private

  def generate_slug
    if name.present? && (slug.blank? || name_changed?)
      self.slug = name.downcase.gsub(/[^a-z0-9]+/, "-")
    end
  end

  def setup_tenants
    return unless slug.present?

    return if Rails.env.test?

    begin
      ApplicationRecord.create_tenant(slug)
    rescue ActiveRecord::Tenanted::TenantExistsError
      Rails.logger.info "ApplicationRecord tenant already exists: #{slug}"
    rescue => e
      Rails.logger.error "Failed to create ApplicationRecord tenant for #{slug}: #{e.message}"
      raise e
    end
  end

  def cleanup_tenants
    return unless slug.present?

    begin
      ApplicationRecord.destroy_tenant(slug)
    rescue => e
      Rails.logger.error "Failed to destroy ApplicationRecord tenant for #{slug}: #{e.message}"
      raise e
    end
  end
end
