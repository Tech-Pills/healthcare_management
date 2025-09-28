require "test_helper"

class AppointmentMailerTest < ActionMailer::TestCase
  setup do
    @appointment = appointments(:one)
    @practice = practices(:one)
  end

  test "reminder_email" do
    email = AppointmentMailer.with(appointment: @appointment).reminder_email("24_hours")

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ @practice.email ], email.from
    assert_equal [ @appointment.patient.email ], email.to
    assert_equal "Appointment Reminder - #{@practice.name}", email.subject

    text_part = email.parts.find { |part| part.content_type.match?(/text\/plain/) }
    assert_equal read_fixture("reminder").join, text_part.body.to_s.strip
  end
end
