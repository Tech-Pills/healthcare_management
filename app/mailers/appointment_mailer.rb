class AppointmentMailer < ApplicationMailer
  before_action :set_appointment_and_practice
  default from: -> { @practice&.email || "no-reply@example.com" }

  def reminder_email(appointment, reminder_period)
    @reminder_period = reminder_period
    mail(
      to: @appointment.patient.email,
      subject: "Appointment Reminder - #{@practice.name}"
    )
  end

  private

  def set_appointment_and_practice
    @appointment = params[:appointment]
    @practice = @appointment&.practice
  end
end
