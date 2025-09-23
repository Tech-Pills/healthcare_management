class AppointmentMailer < ApplicationMailer
  default from: "notifications@example.com"

  def reminder_email(appointment, reminder_period)
    @appointment = appointment
    @reminder_period = reminder_period
    @practice = @appointment.practice
    mail(to: @appointment.patient.email, subject: "Appointment Reminder")
  end
end
