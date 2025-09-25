require "test_helper"

class AppointmentTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  test "belongs to practice, patient, and provider" do
    appointment = Appointment.create!(
      practice_id: practices(:one).id,
      patient: patients(:one),
      provider: staffs(:admin),
      scheduled_at: 1.day.from_now,
      duration_minutes: 30
    )

    assert_respond_to appointment, :practice
    assert_respond_to appointment, :patient
    assert_respond_to appointment, :provider

    assert appointment.practice.is_a?(Practice)
    assert appointment.patient.is_a?(Patient)
    assert appointment.provider.is_a?(Staff)
  end

  test "validates presence of scheduled_at" do
    appointment = Appointment.new(
      practice_id: practices(:one).id,
      patient_id: patients(:one).id,
      provider_id: staffs(:admin).id
    )

    assert_not appointment.valid?
    assert_includes appointment.errors[:scheduled_at], "can't be blank"
  end

  test "validates duration_minutes is positive integer" do
    appointment = Appointment.create!(
      practice_id: practices(:one).id,
      patient: patients(:one),
      provider: staffs(:admin),
      scheduled_at: 1.day.from_now,
      duration_minutes: 45
    )

    appointment.duration_minutes = 0
    assert_not appointment.valid?
    assert_includes appointment.errors[:duration_minutes], "must be greater than 0"

    appointment.duration_minutes = -10
    assert_not appointment.valid?
    assert_includes appointment.errors[:duration_minutes], "must be greater than 0"

    appointment.duration_minutes = 30.5
    assert_not appointment.valid?
    assert_includes appointment.errors[:duration_minutes], "must be an integer"

    appointment.duration_minutes = 30
    appointment.valid?
    assert_not appointment.errors[:duration_minutes].any?
  end

  test "status enum works correctly" do
    appointment = Appointment.create!(
      practice_id: practices(:one).id,
      patient: patients(:one),
      provider: staffs(:admin),
      scheduled_at: 1.day.from_now,
      duration_minutes: 60
    )

    assert_equal "scheduled", appointment.status
    assert appointment.scheduled?

    appointment.completed!
    assert appointment.completed?
    assert_equal "completed", appointment.status

    appointment.canceled!
    assert appointment.canceled?

    appointment.no_show!
    assert appointment.no_show?
  end

  test "can create appointment with all required fields" do
    appointment = Appointment.new(
      practice_id: practices(:one).id,
      patient_id: patients(:one).id,
      provider_id: staffs(:admin).id,
      scheduled_at: 1.day.from_now,
      duration_minutes: 45,
      notes: "Follow-up appointment"
    )

    assert appointment.valid?
    assert appointment.save
  end

  test "schedules reminders via service on creation" do
    assert_enqueued_jobs 2, only: AppointmentReminderJob do
      Appointment.create!(
        practice_id: practices(:one).id,
        patient: patients(:one),
        provider: staffs(:admin),
        scheduled_at: 48.hours.from_now,
        duration_minutes: 30
      )
    end
  end
end
