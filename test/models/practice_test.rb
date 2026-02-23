require "test_helper"

class PracticeTest < ActiveSupport::TestCase
  test "validates presence of required fields" do
    practice = Practice.new

    assert_not practice.valid?
    assert_includes practice.errors[:name], "can't be blank"
    assert_includes practice.errors[:address], "can't be blank"
    assert_includes practice.errors[:phone], "can't be blank"
    assert_includes practice.errors[:email], "can't be blank"
    assert_includes practice.errors[:license_number], "can't be blank"
  end

  test "validates email format" do
    practice = Practice.create!(
      name: "Test Practice",
      address: "123 Test St",
      phone: "555-0123",
      email: "test@example.com",
      license_number: "TEST-EMAIL"
    )

    practice.email = "invalid-email"
    assert_not practice.valid?
    assert_includes practice.errors[:email], "is invalid"

    practice.email = "valid@example.com"
    practice.valid?
    assert_not practice.errors[:email].any?
  end

  test "validates license_number uniqueness" do
    practice = Practice.create!(
      name: "First Practice",
      address: "123 First St",
      phone: "555-0001",
      email: "first@example.com",
      license_number: "UNIQUE-001"
    )

    new_practice = Practice.new(
      name: "New Practice",
      address: "123 New St",
      phone: "555-0000",
      email: "new@example.com",
      license_number: practice.license_number
    )

    assert_not new_practice.valid?
    assert_includes new_practice.errors[:license_number], "has already been taken"
  end

  test "has many staffs" do
    practice = practices(:one)

    assert_respond_to practice, :staffs
    assert practice.staffs.respond_to?(:each)
  end

  test "has many patients" do
    practice = practices(:one)

    assert_respond_to practice, :patients
    assert practice.patients.respond_to?(:each)
  end

  test "has many appointments" do
    practice = practices(:one)

    assert_respond_to practice, :appointments
    assert practice.appointments.respond_to?(:each)
  end

  test "has many users through staffs" do
    practice = practices(:one)

    assert_respond_to practice, :users
    assert practice.users.respond_to?(:each)
  end

  test "users association returns correct records through staffs" do
    practice = practices(:one)

    users = practice.users.to_a

    assert_equal 2, users.count
    assert_includes users.map(&:id), users(:one).id
    assert_includes users.map(&:id), users(:two).id

    users.each do |user|
      assert Staff.exists?(user_id: user.id, practice_id: practice.id),
             "User #{user.id} should have staff record for practice #{practice.id}"
    end
  end

  test "staffs association returns correct records from tenant database" do
    practice = practices(:one)

    staffs = practice.staffs.to_a

    assert_equal 2, staffs.count
    assert_includes staffs.map(&:id), staffs(:admin).id
    assert_includes staffs.map(&:id), staffs(:doctor).id
    assert staffs.all? { |s| s.practice_id == practice.id }
  end

  test "patients association returns correct records from tenant database" do
    practice = practices(:one)

    patients = practice.patients.to_a

    assert_equal 2, patients.count
    assert_includes patients.map(&:id), patients(:one).id
    assert_includes patients.map(&:id), patients(:two).id
    assert patients.all? { |p| p.practice_id == practice.id }
  end

  test "patients association queries tenant database not global database" do
    practice = practices(:one)

    assert_equal "primary_test-medical-center", Patient.connection_db_config.name
    assert_includes Patient.connection_db_config.database, "test/test-medical-center"

    assert_equal "global", Practice.connection_db_config.name
    assert_includes Practice.connection_db_config.database, "test_global"

    assert_equal 2, practice.patients.count

    patient = practice.patients.first
    assert_instance_of Patient, patient
    assert_equal practice.id, patient.practice_id
  end

  test "staffs association queries tenant database not global database" do
    practice = practices(:one)

    assert_equal "primary_test-medical-center", Staff.connection_db_config.name

    assert_equal "global", Practice.connection_db_config.name

    assert_equal 2, practice.staffs.count

    staff = practice.staffs.first
    assert_instance_of Staff, staff
    assert_equal practice.id, staff.practice_id
  end

  test "associations work with chaining and scopes" do
    practice = practices(:one)

    active_patients = practice.patients.where(active: true)
    assert_equal 2, active_patients.count

    admin_staff = practice.staffs.where(role: "admin")
    assert_equal 1, admin_staff.count
    assert_equal staffs(:admin).id, admin_staff.first.id
  end

  test "associations raise error when no current tenant" do
    practice = practices(:one)
    ApplicationRecord.current_tenant = nil

    # Without tenant context, queries should fail
    # (activerecord-tenanted enforces tenant context)
    assert_raises(ActiveRecord::Tenanted::TenantDoesNotExistError) do
      practice.patients.to_a
    end
  ensure
    # Restore default tenant for subsequent tests
    ApplicationRecord.current_tenant = "test-medical-center"
  end
end
