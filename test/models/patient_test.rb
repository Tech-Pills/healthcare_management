require "test_helper"

class PatientTest < ActiveSupport::TestCase
  test "belongs to practice" do
    patient = Patient.create!(
      practice_id: 1, # Use fixture practice id
      first_name: "John",
      last_name: "Doe", 
      date_of_birth: 30.years.ago,
      phone: "555-1234",
      email: "john.doe@example.com"
    )

    assert_respond_to patient, :practice
    assert patient.practice.is_a?(Practice)
  end

  test "has many appointments" do
    patient = Patient.create!(
      practice_id: 1,
      first_name: "Jane",
      last_name: "Smith", 
      date_of_birth: 25.years.ago,
      phone: "555-5678",
      email: "jane.smith@example.com"
    )

    assert_respond_to patient, :appointments
    assert patient.appointments.respond_to?(:each)
  end

  test "validates presence of required fields" do
    patient = Patient.new(practice_id: 1)

    assert_not patient.valid?
    assert_includes patient.errors[:first_name], "can't be blank"
    assert_includes patient.errors[:last_name], "can't be blank"
    assert_includes patient.errors[:date_of_birth], "can't be blank"
    assert_includes patient.errors[:phone], "can't be blank"
  end

  test "validates email format when provided" do
    patient = Patient.create!(
      practice_id: 1,
      first_name: "Email",
      last_name: "Test", 
      date_of_birth: 28.years.ago,
      phone: "555-9999",
      email: "email.test@example.com"
    )

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
      practice_id: 1,
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
    patient = Patient.create!(
      practice_id: 1,
      first_name: "Blood",
      last_name: "Type", 
      date_of_birth: 35.years.ago,
      phone: "555-0000",
      email: "blood.type@example.com"
    )

    patient.blood_type_a_positive!
    assert patient.blood_type_a_positive?
    assert_equal "a_positive", patient.blood_type

    patient.blood_type_o_negative!
    assert patient.blood_type_o_negative?
    assert_equal "o_negative", patient.blood_type

    expected_keys = %w[a_positive a_negative b_positive b_negative ab_positive ab_negative o_positive o_negative]
    actual_keys = Patient.blood_types.keys

    expected_keys.each do |key|
      assert_includes actual_keys, key
    end
  end
end
