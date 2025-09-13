class Practice < GlobalRecord
  validates :name, presence: true
  validates :address, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true
  validates :license_number, presence: true, uniqueness: true

  def slug
    name.downcase.gsub(/[^a-z0-9]+/, "-")
  end
end
