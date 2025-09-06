require "application_system_test_case"

class PatientsTest < ApplicationSystemTestCase
  setup do
    @patient = patients(:one)
  end

  test "visiting the index" do
    visit patients_url
    assert_selector "h1", text: "Patients"
  end

  test "should create patient" do
    visit patients_url
    click_on "New patient"

    check "Active" if @patient.active
    fill_in "Address", with: @patient.address
    fill_in "Blood type", with: @patient.blood_type
    fill_in "Date of birth", with: @patient.date_of_birth
    fill_in "Email", with: @patient.email
    fill_in "Emergency contact name", with: @patient.emergency_contact_name
    fill_in "Emergency contact phone", with: @patient.emergency_contact_phone
    fill_in "First name", with: @patient.first_name
    fill_in "Gender", with: @patient.gender
    fill_in "Insurance policy number", with: @patient.insurance_policy_number
    fill_in "Insurance provider", with: @patient.insurance_provider
    fill_in "Last name", with: @patient.last_name
    fill_in "Phone", with: @patient.phone
    select @patient.practice.name, from: "Practice"
    click_on "Create Patient"

    assert_text "Patient was successfully created"
    click_on "Back"
  end

  test "should update Patient" do
    visit patient_url(@patient)
    click_on "Edit this patient", match: :first

    check "Active" if @patient.active
    fill_in "Address", with: @patient.address
    fill_in "Blood type", with: @patient.blood_type
    fill_in "Date of birth", with: @patient.date_of_birth
    fill_in "Email", with: @patient.email
    fill_in "Emergency contact name", with: @patient.emergency_contact_name
    fill_in "Emergency contact phone", with: @patient.emergency_contact_phone
    fill_in "First name", with: @patient.first_name
    fill_in "Gender", with: @patient.gender
    fill_in "Insurance policy number", with: @patient.insurance_policy_number
    fill_in "Insurance provider", with: @patient.insurance_provider
    fill_in "Last name", with: @patient.last_name
    fill_in "Phone", with: @patient.phone
    click_on "Update Patient"

    assert_text "Patient was successfully updated"
    click_on "Back"
  end

  test "should destroy Patient" do
    visit patient_url(@patient)
    click_on "Destroy this patient", match: :first

    assert_text "Patient was successfully destroyed"
  end
end
