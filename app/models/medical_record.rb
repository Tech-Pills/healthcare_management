class MedicalRecord < ApplicationRecord
  belongs_to :patient
  belongs_to :appointment, optional: true

  has_one_attached :x_ray_image
  has_many_attached :lab_results

  validates :recorded_at, presence: true
  validates :weight, :height, numericality: { greater_than: 0 }, allow_blank: true
  validates :heart_rate, numericality: { greater_than: 0, less_than: 300 }, allow_blank: true
  validates :temperature, numericality: { greater_than: 0, less_than: 50 }, allow_blank: true
  validates :blood_pressure_systolic, :blood_pressure_diastolic,
            numericality: { greater_than: 0, less_than: 300 }, allow_blank: true

  def blood_pressure
    return nil unless blood_pressure_systolic.present? && blood_pressure_diastolic.present?
    "#{blood_pressure_systolic}/#{blood_pressure_diastolic}"
  end

  def practice
    patient&.practice
  end
end
