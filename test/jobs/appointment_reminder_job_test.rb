require "test_helper"

class AppointmentReminderJobTest < ActiveJob::TestCase
  setup do
    @appointment = appointments(:one)
  end

  test "appointment reminder email is sent" do
    reminder_period = "24_hours"

    AppointmentReminderJob.perform_later(@appointment.id, reminder_period)

    perform_enqueued_jobs

    assert_not ActionMailer::Base.deliveries.empty?
    email = ActionMailer::Base.deliveries.last
    assert_equal [ @appointment.patient.email ], email.to
    assert_equal [ @appointment.practice.email ], email.from
    assert_equal "Appointment Reminder - #{@appointment.practice.name}", email.subject
  end
end
