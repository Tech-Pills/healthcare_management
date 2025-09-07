require "application_system_test_case"

class AppointmentsTest < ApplicationSystemTestCase
  setup do
    @appointment = appointments(:one)
  end

  test "visiting the index" do
    visit appointments_url
    assert_selector "h1", text: "Appointments"
  end

  test "should create appointment" do
    visit appointments_url
    click_on "New appointment"

    fill_in "Duration minutes", with: @appointment.duration_minutes
    fill_in "Notes", with: @appointment.notes
    fill_in "Patient", with: @appointment.patient_id
    fill_in "Practice", with: @appointment.practice_id
    fill_in "Provider", with: @appointment.provider_id
    fill_in "Scheduled at", with: @appointment.scheduled_at
    fill_in "Status", with: @appointment.status
    click_on "Create Appointment"

    assert_text "Appointment was successfully created"
    click_on "Back"
  end

  test "should update Appointment" do
    visit appointment_url(@appointment)
    click_on "Edit this appointment", match: :first

    fill_in "Duration minutes", with: @appointment.duration_minutes
    fill_in "Notes", with: @appointment.notes
    fill_in "Patient", with: @appointment.patient_id
    fill_in "Practice", with: @appointment.practice_id
    fill_in "Provider", with: @appointment.provider_id
    fill_in "Scheduled at", with: @appointment.scheduled_at.to_s
    fill_in "Status", with: @appointment.status
    click_on "Update Appointment"

    assert_text "Appointment was successfully updated"
    click_on "Back"
  end

  test "should destroy Appointment" do
    visit appointment_url(@appointment)
    click_on "Destroy this appointment", match: :first

    assert_text "Appointment was successfully destroyed"
  end
end
