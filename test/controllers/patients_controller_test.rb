require "test_helper"

class PatientsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @patient = patients(:one)
  end

  test "should get index" do
    get patients_url
    assert_response :success
  end

  test "should get new" do
    get new_patient_url
    assert_response :success
  end

  test "should create patient" do
    assert_difference("Patient.count") do
      post patients_url, params: { patient: { active: @patient.active, address: @patient.address, blood_type: @patient.blood_type, date_of_birth: @patient.date_of_birth, email: "unique_patient@example.com", emergency_contact_name: @patient.emergency_contact_name, emergency_contact_phone: @patient.emergency_contact_phone, first_name: @patient.first_name, gender: @patient.gender, insurance_policy_number: @patient.insurance_policy_number, insurance_provider: @patient.insurance_provider, last_name: @patient.last_name, practice_id: @patient.practice_id, phone: @patient.phone } }
    end

    assert_redirected_to patient_url(Patient.last)
  end

  test "should show patient" do
    get patient_url(@patient)
    assert_response :success
  end

  test "should get edit" do
    get edit_patient_url(@patient)
    assert_response :success
  end

  test "should update patient" do
    patch patient_url(@patient), params: { patient: { active: @patient.active, address: @patient.address, blood_type: @patient.blood_type, date_of_birth: @patient.date_of_birth, email: @patient.email, emergency_contact_name: @patient.emergency_contact_name, emergency_contact_phone: @patient.emergency_contact_phone, first_name: @patient.first_name, gender: @patient.gender, insurance_policy_number: @patient.insurance_policy_number, insurance_provider: @patient.insurance_provider, last_name: @patient.last_name, practice_id: @patient.practice_id, phone: @patient.phone } }
    assert_redirected_to patient_url(@patient)
  end

  test "should destroy patient" do
    assert_difference("Patient.count", -1) do
      delete patient_url(@patient)
    end

    assert_redirected_to patients_url
  end
end
