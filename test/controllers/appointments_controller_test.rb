require "test_helper"

class AppointmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    load_appointment_fixtures
    @appointment = Appointment.find(1)
  end

  private

  def load_appointment_fixtures
    # Load patients first (appointments depend on them)
    PatientsRecord.with_tenant('test-medical-center') do
      Patient.create!(
        id: 1,
        practice_id: 1,
        first_name: "John",
        last_name: "Doe",
        date_of_birth: Date.new(1980, 1, 1),
        gender: "Male",
        phone: "555-0123", 
        email: "john.doe@example.com",
        address: "123 Test St",
        emergency_contact_name: "Jane Doe",
        emergency_contact_phone: "555-0124",
        insurance_provider: "Test Insurance",
        insurance_policy_number: "POL123",
        blood_type: "o_positive",
        active: true
      ) unless Patient.exists?(1)
    end

    # Load staff (appointments depend on them as providers) + appointments
    ApplicationRecord.with_tenant('test-medical-center') do
      Staff.create!(
        id: 1,
        user_id: 1,
        practice_id: 1,
        first_name: "John",
        last_name: "Admin",
        role: "admin", 
        license_number: "ADMIN123",
        active: false
      ) unless Staff.exists?(1)
      
      Staff.create!(
        id: 2,
        user_id: 2,
        practice_id: 1,
        first_name: "Jane",
        last_name: "Doctor",
        role: "doctor",
        license_number: "DOC456", 
        active: true
      ) unless Staff.exists?(2)

      # Now load appointments
      Appointment.create!(
        id: 1,
        practice_id: 1,
        patient_id: 1,
        provider_id: 1,
        scheduled_at: Time.parse("2025-09-07 13:52:46"),
        duration_minutes: 30,
        status: "scheduled",
        notes: "MyText"
      ) unless Appointment.exists?(1)
      
      Appointment.create!(
        id: 2,
        practice_id: 1,
        patient_id: 1,
        provider_id: 2,
        scheduled_at: Time.parse("2025-09-07 13:52:46"),
        duration_minutes: 60,
        status: "scheduled", 
        notes: "MyText"
      ) unless Appointment.exists?(2)
    end
  end

  test "should get index" do
    get appointments_url
    assert_response :success
  end

  test "should get new" do
    get new_appointment_url
    assert_response :success
  end

  test "should create appointment" do
    assert_difference("Appointment.count") do
      post appointments_url, params: { appointment: { duration_minutes: @appointment.duration_minutes, notes: @appointment.notes, patient_id: @appointment.patient_id, practice_id: @appointment.practice_id, provider_id: @appointment.provider_id, scheduled_at: @appointment.scheduled_at, status: @appointment.status } }
    end

    assert_redirected_to appointment_url(Appointment.last)
  end

  test "should show appointment" do
    get appointment_url(@appointment)
    assert_response :success
  end

  test "should get edit" do
    get edit_appointment_url(@appointment)
    assert_response :success
  end

  test "should update appointment" do
    patch appointment_url(@appointment), params: { appointment: { duration_minutes: @appointment.duration_minutes, notes: @appointment.notes, patient_id: @appointment.patient_id, practice_id: @appointment.practice_id, provider_id: @appointment.provider_id, scheduled_at: @appointment.scheduled_at, status: @appointment.status } }
    assert_redirected_to appointment_url(@appointment)
  end

  test "should destroy appointment" do
    assert_difference("Appointment.count", -1) do
      delete appointment_url(@appointment)
    end

    assert_redirected_to appointments_url
  end
end
