require "test_helper"

class AppointmentNotificationsTest < ActionDispatch::IntegrationTest
  include ActionCable::TestHelper

  setup do
    @practice_one = practices(:one)
    @practice_two = practices(:two)

    @user_one = users(:one)
    @staff_one = staffs(:admin)
    @staff_two = staffs(:doctor)
    @patient_one = patients(:one)

    @user_one.update!(staff: @staff_one)
    @staff_one.update!(practice_id: @practice_one.id)
    @staff_two.update!(practice_id: @practice_one.id)
    @patient_one.update!(practice_id: @practice_one.id)
  end

  test "broadcasts appointment creation to staff stream" do
    stream = AppointmentChannel.broadcasting_for(@staff_one)

    assert_broadcasts(stream, 1) do
      Appointment.create!(
        practice_id: @practice_one.id,
        patient_id: @patient_one.id,
        provider_id: @staff_one.id,
        scheduled_at: 1.day.from_now,
        duration_minutes: 30,
        status: "scheduled"
      )
    end
  end

  test "broadcasts appointment update to staff stream" do
    appointment = appointments(:one)
    appointment.update!(practice_id: @practice_one.id, patient_id: @patient_one.id, provider_id: @staff_one.id)
    stream = AppointmentChannel.broadcasting_for(@staff_one)

    assert_broadcasts(stream, 1) do
      appointment.update!(status: "completed")
    end
  end

  test "broadcasts appointment destruction to staff stream" do
    appointment = appointments(:one)
    appointment.update!(practice_id: @practice_one.id, patient_id: @patient_one.id, provider_id: @staff_one.id)
    stream = AppointmentChannel.broadcasting_for(@staff_one)

    assert_broadcasts(stream, 1) do
      appointment.destroy!
    end
  end

  test "broadcasts to all staff members in the same practice" do
    stream_one = AppointmentChannel.broadcasting_for(@staff_one)
    stream_two = AppointmentChannel.broadcasting_for(@staff_two)

    assert_broadcasts(stream_one, 1) do
      assert_broadcasts(stream_two, 1) do
        Appointment.create!(
          practice_id: @practice_one.id,
          patient_id: @patient_one.id,
          provider_id: @staff_one.id,
          scheduled_at: 1.day.from_now,
          duration_minutes: 30,
          status: "scheduled"
        )
      end
    end
  end

  test "staff stream global id includes tenant parameter" do
    stream = AppointmentChannel.broadcasting_for(@staff_one)

    require "base64"
    encoded = stream.split(":").last
    decoded = Base64.urlsafe_decode64(encoded)

    assert_includes decoded, "tenant="
  end

  test "broadcast contains correct action field for create" do
    stream = AppointmentChannel.broadcasting_for(@staff_one)

    messages = capture_broadcasts(stream) do
      Appointment.create!(
        practice_id: @practice_one.id,
        patient_id: @patient_one.id,
        provider_id: @staff_one.id,
        scheduled_at: 1.day.from_now,
        duration_minutes: 30,
        status: "scheduled"
      )
    end

    assert_equal 1, messages.length
    assert_equal "created", messages.first["action"]
    assert_includes messages.first.keys, "appointment"
  end

  test "broadcast contains correct action field for update" do
    appointment = appointments(:one)
    appointment.update!(practice_id: @practice_one.id, patient_id: @patient_one.id, provider_id: @staff_one.id)
    stream = AppointmentChannel.broadcasting_for(@staff_one)

    messages = capture_broadcasts(stream) do
      appointment.update!(status: "completed")
    end

    assert_equal 1, messages.length
    assert_equal "updated", messages.first["action"]
  end

  test "broadcast contains correct action field for destroy" do
    appointment = appointments(:one)
    appointment.update!(practice_id: @practice_one.id, patient_id: @patient_one.id, provider_id: @staff_one.id)
    stream = AppointmentChannel.broadcasting_for(@staff_one)

    messages = capture_broadcasts(stream) do
      appointment.destroy!
    end

    assert_equal 1, messages.length
    assert_equal "destroyed", messages.first["action"]
  end

  test "broadcast payload includes appointment id" do
    stream = AppointmentChannel.broadcasting_for(@staff_one)

    messages = capture_broadcasts(stream) do
      Appointment.create!(
        practice_id: @practice_one.id,
        patient_id: @patient_one.id,
        provider_id: @staff_one.id,
        scheduled_at: 1.day.from_now,
        duration_minutes: 30,
        status: "scheduled"
      )
    end

    appointment_data = messages.first["appointment"]
    assert_not_nil appointment_data["id"]
    assert_instance_of Integer, appointment_data["id"]
  end

  test "broadcast payload includes patient and provider names" do
    stream = AppointmentChannel.broadcasting_for(@staff_one)

    messages = capture_broadcasts(stream) do
      Appointment.create!(
        practice_id: @practice_one.id,
        patient_id: @patient_one.id,
        provider_id: @staff_one.id,
        scheduled_at: 1.day.from_now,
        duration_minutes: 30,
        status: "scheduled"
      )
    end

    appointment_data = messages.first["appointment"]
    assert_includes appointment_data.keys, "patient_name"
    assert_includes appointment_data.keys, "provider_name"
    assert_equal @patient_one.full_name, appointment_data["patient_name"]
    assert_equal @staff_one.full_name, appointment_data["provider_name"]
  end

  test "broadcast payload includes formatted scheduled time" do
    stream = AppointmentChannel.broadcasting_for(@staff_one)
    scheduled_time = Time.zone.parse("2026-03-15 14:30:00")

    messages = capture_broadcasts(stream) do
      Appointment.create!(
        practice_id: @practice_one.id,
        patient_id: @patient_one.id,
        provider_id: @staff_one.id,
        scheduled_at: scheduled_time,
        duration_minutes: 30,
        status: "scheduled"
      )
    end

    appointment_data = messages.first["appointment"]
    assert_includes appointment_data.keys, "scheduled_at"
    assert_match(/March \d{2}, \d{4} at \d{2}:\d{2} (AM|PM)/, appointment_data["scheduled_at"])
  end

  test "broadcast payload includes status and duration" do
    stream = AppointmentChannel.broadcasting_for(@staff_one)

    messages = capture_broadcasts(stream) do
      Appointment.create!(
        practice_id: @practice_one.id,
        patient_id: @patient_one.id,
        provider_id: @staff_one.id,
        scheduled_at: 1.day.from_now,
        duration_minutes: 45,
        status: "scheduled"
      )
    end

    appointment_data = messages.first["appointment"]
    assert_equal "scheduled", appointment_data["status"]
    assert_equal 45, appointment_data["duration_minutes"]
  end
end
