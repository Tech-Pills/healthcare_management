require "test_helper"

class PracticeBasicTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def setup
    # Clean up any existing test practices
    Practice.where(license_number: "TEST-001").destroy_all
  end

  def teardown
    # Clean up after tests
    Practice.where(license_number: "TEST-001").destroy_all
  end

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
    practice = Practice.new(
      name: "Test Practice",
      address: "123 Test St",
      phone: "555-0123",
      license_number: "TEST-001"
    )

    practice.email = "invalid-email"
    assert_not practice.valid?
    assert_includes practice.errors[:email], "is invalid"

    practice.email = "valid@example.com"
    assert practice.valid?
    assert_not practice.errors[:email].any?
  end

  test "validates license_number uniqueness" do
    # Create first practice
    practice1 = Practice.create!(
      name: "First Practice",
      address: "123 First St",
      phone: "555-0001",
      email: "first@example.com",
      license_number: "TEST-001"
    )

    # Try to create second with same license
    practice2 = Practice.new(
      name: "Second Practice",
      address: "456 Second St",
      phone: "555-0002",
      email: "second@example.com",
      license_number: "TEST-001"
    )

    assert_not practice2.valid?
    assert_includes practice2.errors[:license_number], "has already been taken"
  end

  test "generates slug automatically" do
    practice = Practice.create!(
      name: "Unique Medical Center",
      address: "789 Test Ave",
      phone: "555-0789",
      email: "test@example.com",
      license_number: "TEST-001"
    )

    assert_equal "unique-medical-center", practice.slug
  end

  test "skips tenant creation in test environment" do
    initial_app_tenants = ApplicationRecord.tenants.size

    practice = Practice.create!(
      name: "Auto Tenant Practice",
      address: "321 Auto St",
      phone: "555-0321",
      email: "auto@example.com",
      license_number: "TEST-001"
    )

    assert_equal initial_app_tenants, ApplicationRecord.tenants.size
  end
end
