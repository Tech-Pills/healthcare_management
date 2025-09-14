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
end
