require "application_system_test_case"

class MedicalRecordsTest < ApplicationSystemTestCase
  setup do
    @practice = practices(:one)
    @patient = patients(:one)
    @appointment = appointments(:one)
    @medical_record = MedicalRecord.create!(
      patient: @patient,
      appointment: @appointment,
      recorded_at: Time.current,
      weight: 70.5,
      height: 175.0,
      heart_rate: 72,
      temperature: 36.7,
      blood_pressure_systolic: 120,
      blood_pressure_diastolic: 80,
      diagnosis: "Routine checkup",
      medications: "Vitamin D supplement",
      allergies: "None known",
      notes: "Patient reports feeling well"
    )
  end

  test "visiting the index" do
    visit medical_records_url
    assert_selector "h1", text: "Medical records"
  end

  test "should create medical record" do
    visit medical_records_url
    click_on "New medical record"

    select @patient.full_name, from: "medical_record_patient_id"
    select @appointment.id.to_s, from: "medical_record_appointment_id"
    fill_in "medical_record_weight", with: 75.0
    fill_in "medical_record_height", with: 180.0
    fill_in "medical_record_heart_rate", with: 75
    fill_in "medical_record_temperature", with: 36.8
    fill_in "medical_record_blood_pressure_systolic", with: 125
    fill_in "medical_record_blood_pressure_diastolic", with: 85
    fill_in "medical_record_diagnosis", with: "Test diagnosis"
    fill_in "medical_record_medications", with: "Test medications"
    fill_in "medical_record_allergies", with: "Test allergies"
    fill_in "medical_record_notes", with: "Test notes"
    click_on "Create Medical record"

    assert_text "Medical record was successfully created"
    click_on "Back"
  end

  test "should update Medical record" do
    visit medical_record_url(@medical_record)
    click_on "Edit this medical record", match: :first

    fill_in "medical_record_weight", with: 72.0
    fill_in "medical_record_diagnosis", with: "Updated diagnosis"
    click_on "Update Medical record"

    assert_text "Medical record was successfully updated"
    click_on "Back"
  end

  test "should destroy Medical record" do
    visit medical_record_url(@medical_record)
    click_on "Destroy this medical record", match: :first

    assert_text "Medical record was successfully destroyed"
  end
end
