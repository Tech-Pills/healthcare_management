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

  test "belongs_to practice association" do
    appointment = appointments(:one)

    assert_respond_to appointment, :practice
    assert_instance_of Practice, appointment.practice
  end

  test "practice association returns correct record" do
    appointment = appointments(:one)
    practice = appointment.practice

    assert_equal practices(:one).id, practice.id
    assert_equal "Test Medical Center", practice.name
    assert_equal appointment.practice_id, practice.id
  end

  test "practice association queries across databases" do
    appointment = appointments(:one)

    assert_equal "primary_test-medical-center", Appointment.connection_db_config.name
    assert_includes Appointment.connection_db_config.database, "test/test-medical-center"

    assert_equal "global", Practice.connection_db_config.name
    assert_includes Practice.connection_db_config.database, "test_global"

    practice = appointment.practice
    assert_not_nil practice
    assert_instance_of Practice, practice
  end

  test "belongs_to patient association" do
    appointment = appointments(:one)

    assert_respond_to appointment, :patient
    assert_instance_of Patient, appointment.patient
  end

  test "patient association queries same tenant database" do
    appointment = appointments(:one)

    assert_equal "primary_test-medical-center", Appointment.connection_db_config.name
    assert_equal "primary_test-medical-center", Patient.connection_db_config.name

    patient = appointment.patient
    assert_not_nil patient
    assert_instance_of Patient, patient
  end

  test "belongs_to provider association" do
    appointment = appointments(:one)

    assert_respond_to appointment, :provider
    assert_instance_of Staff, appointment.provider
  end

  test "provider association queries same tenant database" do
    appointment = appointments(:one)

    assert_equal "primary_test-medical-center", Appointment.connection_db_config.name
    assert_equal "primary_test-medical-center", Staff.connection_db_config.name

    provider = appointment.provider
    assert_not_nil provider
    assert_instance_of Staff, provider
  end

  test "has_many medical_records association" do
    appointment = appointments(:one)

    assert_respond_to appointment, :medical_records
    assert appointment.medical_records.is_a?(ActiveRecord::Associations::CollectionProxy)
  end

  test "validates presence of practice_id" do
    appointment = Appointment.new(
      patient_id: patients(:one).id,
      provider_id: staffs(:admin).id,
      scheduled_at: 1.day.from_now,
      duration_minutes: 30
    )

    assert_not appointment.valid?
    assert_includes appointment.errors[:practice_id], "can't be blank"
  end

  test "valid with practice_id" do
    appointment = Appointment.new(
      practice_id: practices(:one).id,
      patient_id: patients(:one).id,
      provider_id: staffs(:admin).id,
      scheduled_at: 1.day.from_now,
      duration_minutes: 30
    )

    assert appointment.valid?
  end

  test "optional: true allows association without existence check" do
    appointment = Appointment.new(
      practice_id: practices(:one).id,
      patient_id: patients(:one).id,
      provider_id: staffs(:admin).id,
      scheduled_at: 1.day.from_now,
      duration_minutes: 30
    )

    assert appointment.valid?
    assert_not_nil appointment.practice
  end
end
