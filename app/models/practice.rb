class Practice < ApplicationRecord
  has_many :staffs, dependent: :destroy
  has_many :users, through: :staffs

  validates :name, presence: true
  validates :address, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true
  validates :license_number, presence: true, uniqueness: true
end
