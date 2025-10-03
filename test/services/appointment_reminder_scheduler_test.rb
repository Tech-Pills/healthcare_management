require "test_helper"

class AppointmentReminderSchedulerTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @appointment = appointments(:one)
  end

  test "schedules both reminders when appointment is far in future" do
    @appointment.scheduled_at = 48.hours.from_now
    scheduler = AppointmentReminderScheduler.new(@appointment)

    assert_enqueued_jobs 2, only: AppointmentReminderJob do
      scheduler.schedule_reminders
    end
  end

  test "schedules only 2-hour reminder when appointment is within 24 hours" do
    @appointment.scheduled_at = 12.hours.from_now
    scheduler = AppointmentReminderScheduler.new(@appointment)

    assert_enqueued_jobs 1, only: AppointmentReminderJob do
      scheduler.schedule_reminders
    end
  end

  test "schedules no reminders when appointment is within 2 hours" do
    @appointment.scheduled_at = 1.hour.from_now
    scheduler = AppointmentReminderScheduler.new(@appointment)

    assert_no_enqueued_jobs only: AppointmentReminderJob do
      scheduler.schedule_reminders
    end
  end

  test "schedules jobs with correct timing and arguments" do
    scheduled_time = 48.hours.from_now
    @appointment.scheduled_at = scheduled_time
    scheduler = AppointmentReminderScheduler.new(@appointment)

    scheduler.schedule_reminders

    assert_enqueued_with(
      job: AppointmentReminderJob,
      args: [ @appointment.id, "24_hours" ],
      at: scheduled_time - 24.hours
    )

    assert_enqueued_with(
      job: AppointmentReminderJob,
      args: [ @appointment.id, "2_hours" ],
      at: scheduled_time - 2.hours
    )
  end

  test "does not schedule reminders when scheduled_at is not present" do
    @appointment.scheduled_at = nil
    scheduler = AppointmentReminderScheduler.new(@appointment)

    assert_no_enqueued_jobs only: AppointmentReminderJob do
      scheduler.schedule_reminders
    end
  end


  test "schedule_reminder returns correct boolean for 24 hours" do
    scheduler = AppointmentReminderScheduler.new(@appointment)

    @appointment.scheduled_at = 48.hours.from_now
    assert scheduler.send(:schedule_reminder?, 24)

    @appointment.scheduled_at = 12.hours.from_now
    assert_not scheduler.send(:schedule_reminder?, 24)
  end

  test "schedule_reminder returns correct boolean for 2 hours" do
    scheduler = AppointmentReminderScheduler.new(@appointment)

    @appointment.scheduled_at = 12.hours.from_now
    assert scheduler.send(:schedule_reminder?, 2)

    @appointment.scheduled_at = 1.hour.from_now
    assert_not scheduler.send(:schedule_reminder?, 2)
  end

  test "can easily test different reminder intervals" do
    scheduler = AppointmentReminderScheduler.new(@appointment)
    @appointment.scheduled_at = 72.hours.from_now

    assert scheduler.send(:schedule_reminder?, 48), "Schedules 48-hour reminder"
    assert scheduler.send(:schedule_reminder?, 24), "Schedules 24-hour reminder"
    assert scheduler.send(:schedule_reminder?, 2), "Schedules 2-hour reminder"
    assert scheduler.send(:schedule_reminder?, 1), "Schedules 1-hour reminder"
  end
end
