# Preview all emails at http://localhost:3000/rails/mailers/appointment_mailer
class AppointmentMailerPreview < ActionMailer::Preview
  def reminder_email
    AppointmentMailer.with(appointment: Appointment.first).reminder_email("24_hours")
  end
end
