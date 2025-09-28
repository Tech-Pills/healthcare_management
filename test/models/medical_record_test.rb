require "test_helper"

class MedicalRecordTest < ActiveSupport::TestCase
  test "belongs to patient and appointment" do
    medical_record = medical_records(:one)

    assert_respond_to medical_record, :patient
    assert_respond_to medical_record, :appointment
    assert medical_record.patient.is_a?(Patient)
    assert medical_record.appointment.is_a?(Appointment)
  end

  test "validates presence of recorded_at" do
    medical_record = MedicalRecord.new(
      patient: patients(:one),
      appointment: appointments(:one)
    )

    assert_not medical_record.valid?
    assert_includes medical_record.errors[:recorded_at], "can't be blank"
  end

  test "validates numerical values are positive" do
    patient = patients(:one)
    appointment = appointments(:one)

    medical_record = MedicalRecord.create!(
      patient: patient,
      appointment: appointment,
      recorded_at: Time.current
    )

    medical_record.weight = -5
    assert_not medical_record.valid?
    assert_includes medical_record.errors[:weight], "must be greater than 0"

    medical_record.weight = 70.5
    medical_record.height = -5
    assert_not medical_record.valid?
    assert_includes medical_record.errors[:height], "must be greater than 0"
  end

  test "validates heart rate is within reasonable range" do
    patient = patients(:one)
    appointment = appointments(:one)

    medical_record = MedicalRecord.create!(
      patient: patient,
      appointment: appointment,
      recorded_at: Time.current
    )

    medical_record.heart_rate = 0
    assert_not medical_record.valid?
    assert_includes medical_record.errors[:heart_rate], "must be greater than 0"

    medical_record.heart_rate = 400
    assert_not medical_record.valid?
    assert_includes medical_record.errors[:heart_rate], "must be less than 300"

    medical_record.heart_rate = 72
    medical_record.valid?
    assert_not medical_record.errors[:heart_rate].any?
  end

  test "validates temperature is within reasonable range" do
    patient = patients(:one)
    appointment = appointments(:one)

    medical_record = MedicalRecord.create!(
      patient: patient,
      appointment: appointment,
      recorded_at: Time.current
    )

    medical_record.temperature = -1
    assert_not medical_record.valid?
    assert_includes medical_record.errors[:temperature], "must be greater than 0"

    medical_record.temperature = 60
    assert_not medical_record.valid?
    assert_includes medical_record.errors[:temperature], "must be less than 50"

    medical_record.temperature = 36.7
    medical_record.valid?
    assert_not medical_record.errors[:temperature].any?
  end

  test "blood_pressure method returns formatted string" do
    patient = patients(:one)
    appointment = appointments(:one)

    medical_record = MedicalRecord.create!(
      patient: patient,
      appointment: appointment,
      recorded_at: Time.current,
      blood_pressure_systolic: 120,
      blood_pressure_diastolic: 80
    )

    assert_equal "120/80", medical_record.blood_pressure

    medical_record.blood_pressure_systolic = nil
    assert_nil medical_record.blood_pressure
  end

  test "practice method returns patient's practice" do
    medical_record = medical_records(:one)

    assert_equal medical_record.patient.practice, medical_record.practice
  end

  test "can create medical record with all fields" do
    medical_record = MedicalRecord.new(
      patient: patients(:one),
      appointment: appointments(:one),
      recorded_at: Time.current,
      weight: 75.0,
      height: 180.0,
      heart_rate: 75,
      temperature: 36.8,
      blood_pressure_systolic: 125,
      blood_pressure_diastolic: 85,
      diagnosis: "Test diagnosis",
      medications: "Test medications",
      allergies: "Test allergies",
      notes: "Test notes"
    )

    assert medical_record.valid?
    assert medical_record.save
  end
end
