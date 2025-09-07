require "test_helper"

class PatientTest < ActiveSupport::TestCase
  test "belongs to practice" do
    patient = patients(:one)

    assert_respond_to patient, :practice
    assert patient.practice.is_a?(Practice)
  end

  test "has many appointments" do
    patient = patients(:one)

    assert_respond_to patient, :appointments
    assert patient.appointments.respond_to?(:each)
  end

  test "validates presence of required fields" do
    patient = Patient.new(practice: practices(:one))

    assert_not patient.valid?
    assert_includes patient.errors[:first_name], "can't be blank"
    assert_includes patient.errors[:last_name], "can't be blank"
    assert_includes patient.errors[:date_of_birth], "can't be blank"
    assert_includes patient.errors[:phone], "can't be blank"
  end

  test "validates email format when provided" do
    patient = patients(:one)

    patient.email = "invalid-email"
    assert_not patient.valid?
    assert_includes patient.errors[:email], "is invalid"

    patient.email = "valid@example.com"
    assert patient.valid?
    assert_empty patient.errors[:email]

    patient.email = ""
    assert_not patient.valid?
    assert_includes patient.errors[:email], "is invalid"
  end

  test "normalizes email" do
    patient = Patient.new(
      practice: practices(:one),
      first_name: "John",
      last_name: "Doe", 
      date_of_birth: 30.years.ago,
      phone: "555-1234",
      email: "  JOHN@EXAMPLE.COM  "
    )

    patient.valid?
    assert_equal "john@example.com", patient.email
  end

  test "full_name combines first and last name" do
    patient = Patient.new(first_name: "John", last_name: "Doe")
    assert_equal "John Doe", patient.full_name
  end

  test "full_name handles nil names" do
    patient = Patient.new(first_name: "John", last_name: nil)
    assert_equal "John", patient.full_name

    patient = Patient.new(first_name: nil, last_name: "Doe")
    assert_equal "Doe", patient.full_name

    patient = Patient.new(first_name: nil, last_name: nil)
    assert_equal "", patient.full_name
  end

  test "blood_type enum with prefix" do
    patient = patients(:one)

    patient.blood_type_a_positive!
    assert patient.blood_type_a_positive?
    assert_equal "a_positive", patient.blood_type

    patient.blood_type_o_negative!
    assert patient.blood_type_o_negative?
    assert_equal "o_negative", patient.blood_type

    expected_types = %w[A+ A- B+ B- AB+ AB- O+ O-]
    available_types = Patient.blood_types.values

    expected_types.each do |type|
      assert_includes available_types, type
    end
  end
end
