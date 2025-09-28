require "test_helper"

class MedicalRecordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @medical_record = medical_records(:one)
  end

  test "should get index" do
    get medical_records_url
    assert_response :success
  end

  test "should get new" do
    get new_medical_record_url
    assert_response :success
  end

  test "should create medical_record" do
    assert_difference("MedicalRecord.count") do
      post medical_records_url, params: { medical_record: {
        appointment_id: @medical_record.appointment_id,
        patient_id: @medical_record.patient_id,
        recorded_at: Time.current,
        blood_pressure_diastolic: @medical_record.blood_pressure_diastolic,
        blood_pressure_systolic: @medical_record.blood_pressure_systolic,
        diagnosis: @medical_record.diagnosis,
        heart_rate: @medical_record.heart_rate,
        height: @medical_record.height,
        temperature: @medical_record.temperature,
        weight: @medical_record.weight,
        medications: "Test medication",
        allergies: "None",
        notes: "Test notes"
      } }
    end

    assert_redirected_to medical_record_url(MedicalRecord.last)
  end

  test "should show medical_record" do
    get medical_record_url(@medical_record)
    assert_response :success
  end

  test "should get edit" do
    get edit_medical_record_url(@medical_record)
    assert_response :success
  end

  test "should update medical_record" do
    patch medical_record_url(@medical_record), params: { medical_record: {
      appointment_id: @medical_record.appointment_id,
      patient_id: @medical_record.patient_id,
      recorded_at: @medical_record.recorded_at,
      blood_pressure_diastolic: @medical_record.blood_pressure_diastolic,
      blood_pressure_systolic: @medical_record.blood_pressure_systolic,
      diagnosis: @medical_record.diagnosis,
      heart_rate: @medical_record.heart_rate,
      height: @medical_record.height,
      temperature: @medical_record.temperature,
      weight: @medical_record.weight,
      medications: @medical_record.medications,
      allergies: @medical_record.allergies,
      notes: @medical_record.notes
    } }
    assert_redirected_to medical_record_url(@medical_record)
  end

  test "should destroy medical_record" do
    assert_difference("MedicalRecord.count", -1) do
      delete medical_record_url(@medical_record)
    end

    assert_redirected_to medical_records_url
  end
end
