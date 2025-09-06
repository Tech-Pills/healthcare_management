require "test_helper"

class StaffTest < ActiveSupport::TestCase
  test "full_name combines first and last name" do
    staff = Staff.new(first_name: "John", last_name: "Doe")
    assert_equal "John Doe", staff.full_name
  end

  test "full_name handles nil first_name" do
    staff = Staff.new(first_name: nil, last_name: "Doe")
    assert_equal "Doe", staff.full_name
  end

  test "full_name handles nil last_name" do
    staff = Staff.new(first_name: "John", last_name: nil)
    assert_equal "John", staff.full_name
  end

  test "full_name handles both names nil" do
    staff = Staff.new(first_name: nil, last_name: nil)
    assert_equal "", staff.full_name
  end

  test "medical_staff? returns true for doctors and nurses" do
    doctor = Staff.new(role: "doctor")
    nurse = Staff.new(role: "nurse")
    admin = Staff.new(role: "admin")

    assert doctor.medical_staff?
    assert nurse.medical_staff?
    assert_not admin.medical_staff?
  end

  test "can_manage_practice? returns true for admins and managers" do
    admin = Staff.new(role: "admin")
    manager = Staff.new(role: "manager")
    nurse = Staff.new(role: "nurse")

    assert admin.can_manage_practice?
    assert manager.can_manage_practice?
    assert_not nurse.can_manage_practice?
  end
end
