class AppointmentChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user.staff
  end

  def unsubscribed
  end
end
