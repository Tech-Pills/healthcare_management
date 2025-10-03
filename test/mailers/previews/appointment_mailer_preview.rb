# Preview all emails at http://localhost:3000/rails/mailers/appointment_mailer
class AppointmentMailerPreview < ActionMailer::Preview
  def reminder_email
    AppointmentMailer.reminder_email(Appointment.first, "24_hours")
  end
end
