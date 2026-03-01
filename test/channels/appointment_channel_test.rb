require "test_helper"

class AppointmentChannelTest < ActionCable::Channel::TestCase
  setup do
    @practice = practices(:one)
    @user = users(:one)
    @staff = staffs(:admin)

    @user.update!(staff: @staff)
    @staff.update!(practice_id: @practice.id)
  end

  test "subscribes to staff stream" do
    stub_connection current_user: @user

    subscribe

    assert subscription.confirmed?
    assert_has_stream_for @staff
  end

  test "rejects subscription without authenticated user" do
    stub_connection current_user: nil

    assert_raises(NoMethodError) do
      subscribe
    end
  end

  test "subscribes only to own staff stream" do
    other_staff = staffs(:doctor)
    stub_connection current_user: @user

    subscribe

    assert_has_stream_for @staff
    assert_not subscription.streams.include?(AppointmentChannel.broadcasting_for(other_staff))
  end
end
