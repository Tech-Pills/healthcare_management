require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    load_staff_fixtures
  end

  private

  def load_staff_fixtures
    # User tests need Staff records for cross-database relationships
    ApplicationRecord.with_tenant('test-medical-center') do
      Staff.create!(
        id: 1,
        user_id: 1,
        practice_id: 1,
        first_name: "John",
        last_name: "Admin",
        role: "admin", 
        license_number: "ADMIN123",
        active: false
      ) unless Staff.exists?(1)
      
      Staff.create!(
        id: 2,
        user_id: 2,
        practice_id: 1,
        first_name: "Jane",
        last_name: "Doctor",
        role: "doctor",
        license_number: "DOC456", 
        active: true
      ) unless Staff.exists?(2)
    end
  end

  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "staff? returns true when user has staff" do
    user = users(:one)
    assert user.staff?
  end

  test "staff? returns false when user has no staff" do
    user = User.new(email_address: "test@example.com", password: "password")

    assert_not user.staff?
  end

  test "delegates full_name to staff" do
    user = users(:one)
    assert_equal "John Admin", user.full_name
  end

  test "delegates role to staff" do
    user = users(:one)
    assert_equal "admin", user.role
  end

  test "delegates return nil when staff is nil" do
    user = User.new(email_address: "test@example.com", password: "password")

    assert_nil user.full_name
    assert_nil user.role
    assert_nil user.active?
    assert_equal practices(:one), user.practice
  end
end
