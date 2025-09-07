
class Patient < ApplicationRecord
  belongs_to :practice

  has_many :appointments, dependent: :destroy

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :date_of_birth, presence: true
  validates :phone, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

  normalizes :email, with: ->(e) { e.strip.downcase }

  enum :blood_type, {
    a_positive: "A+",
    a_negative: "A-",
    b_positive: "B+",
    b_negative: "B-",
    ab_positive: "AB+",
    ab_negative: "AB-",
    o_positive: "O+",
    o_negative: "O-"
  }, prefix: true

  def full_name
    [ first_name, last_name ].compact.join(" ")
  end
end
