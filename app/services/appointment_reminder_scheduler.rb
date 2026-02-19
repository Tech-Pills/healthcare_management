class AppointmentReminderScheduler
  REMINDER_INTERVALS = [
    { hours: 24, label: "24_hours" },
    { hours: 2, label: "2_hours" }
  ].freeze

  def initialize(appointment)
    @appointment = appointment
  end

  def schedule_reminders
    return unless @appointment.scheduled_at.present?

    REMINDER_INTERVALS.each do |interval|
      schedule_reminder(interval) if schedule_reminder?(interval[:hours])
    end
  end

  private

  def schedule_reminder?(hours)
    @appointment.scheduled_at > hours.hours.from_now
  end

  def schedule_reminder(interval)
    reminder_time = @appointment.scheduled_at - interval[:hours].hours

    AppointmentReminderJob
      .set(wait_until: reminder_time)
      .perform_later(@appointment.id, interval[:label])
  end
end
