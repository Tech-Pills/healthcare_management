class AppointmentReminderJob < ApplicationJob
  queue_as :default

  def perform(appointment_id, reminder_period)
    appointment = Appointment.find(appointment_id)

    AppointmentMailer.reminder_email(appointment, reminder_period).deliver_now
  end
end
