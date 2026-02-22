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

  test "belongs_to practice association" do
    staff = staffs(:admin)

    assert_respond_to staff, :practice
    assert_instance_of Practice, staff.practice
  end

  test "practice association returns correct record" do
    staff = staffs(:admin)
    practice = staff.practice

    assert_equal practices(:one).id, practice.id
    assert_equal "Test Medical Center", practice.name
    assert_equal staff.practice_id, practice.id
  end

  test "belongs_to user association" do
    staff = staffs(:admin)

    assert_respond_to staff, :user
    assert_instance_of User, staff.user
  end

  test "user association returns correct record" do
    staff = staffs(:admin)
    user = staff.user

    assert_equal users(:one).id, user.id
    assert_equal staff.user_id, user.id
  end

  test "practice association queries across databases" do
    staff = staffs(:admin)

    assert_equal "primary_test-medical-center", Staff.connection_db_config.name
    assert_includes Staff.connection_db_config.database, "test/test-medical-center"

    assert_equal "global", Practice.connection_db_config.name
    assert_includes Practice.connection_db_config.database, "test_global"

    practice = staff.practice
    assert_not_nil practice
    assert_instance_of Practice, practice
  end

  test "user association queries same tenant database" do
    staff = staffs(:admin)

    assert_equal "primary_test-medical-center", Staff.connection_db_config.name

    assert_equal "primary_test-medical-center", User.connection_db_config.name

    user = staff.user
    assert_not_nil user
    assert_instance_of User, user
  end

  test "validates presence of practice_id" do
    staff = Staff.new(
      user_id: 1,
      first_name: "Test",
      last_name: "Staff",
      role: "nurse"
    )

    assert_not staff.valid?
    assert_includes staff.errors[:practice_id], "can't be blank"
  end

  test "validates presence of user_id" do
    staff = Staff.new(
      practice_id: 1,
      first_name: "Test",
      last_name: "Staff",
      role: "nurse"
    )

    assert_not staff.valid?
    assert_includes staff.errors[:user_id], "can't be blank"
  end

  test "valid with practice_id and user_id" do
    staff = Staff.new(
      practice_id: practices(:one).id,
      user_id: users(:one).id,
      first_name: "Valid",
      last_name: "Staff",
      role: "doctor"
    )

    assert staff.valid?
  end

  test "optional: true allows association without existence check" do
    staff = Staff.new(
      practice_id: practices(:one).id,
      user_id: users(:one).id,
      first_name: "Test",
      last_name: "Staff",
      role: "nurse"
    )

    assert staff.valid?

    assert_not_nil staff.practice
    assert_not_nil staff.user
  end
end
