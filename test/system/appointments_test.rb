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

    select @appointment.practice.name, from: "Practice"
    select @appointment.patient.full_name, from: "Patient", match: :first
    select @appointment.provider.full_name, from: "Provider"
    fill_in "Scheduled at", with: @appointment.scheduled_at.strftime("%Y-%m-%dT%H:%M")
    fill_in "Duration minutes", with: @appointment.duration_minutes
    fill_in "Status", with: @appointment.status
    fill_in "Notes", with: @appointment.notes
    click_on "Create Appointment"

    assert_text "Appointment was successfully created"
    click_on "Back"
  end

  test "should update Appointment" do
    visit appointment_url(@appointment)
    click_on "Edit this appointment", match: :first

    select @appointment.practice.name, from: "Practice"
    select @appointment.patient.full_name, from: "Patient", match: :first
    select @appointment.provider.full_name, from: "Provider"
    fill_in "Scheduled at", with: @appointment.scheduled_at.strftime("%Y-%m-%dT%H:%M")
    fill_in "Duration minutes", with: @appointment.duration_minutes
    fill_in "Status", with: @appointment.status
    fill_in "Notes", with: @appointment.notes
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
