require "application_system_test_case"

class MedicalRecordsTest < ApplicationSystemTestCase
  setup do
    @practice = practices(:one)
    @patient = patients(:one)
    @appointment = appointments(:one)
    @medical_record = MedicalRecord.create!(
      patient: @patient,
      appointment: @appointment,
      recorded_at: Time.current,
      weight: 70.5,
      height: 175.0,
      heart_rate: 72,
      temperature: 36.7,
      blood_pressure_systolic: 120,
      blood_pressure_diastolic: 80,
      diagnosis: "Routine checkup",
      medications: "Vitamin D supplement",
      allergies: "None known",
      notes: "Patient reports feeling well"
    )
  end

  test "visiting the index" do
    visit medical_records_url
    assert_selector "h1", text: "Medical records"
  end

  test "should create medical record" do
    visit medical_records_url
    click_on "New medical record"

    select @patient.full_name, from: "medical_record_patient_id"
    select @appointment.id.to_s, from: "medical_record_appointment_id"
    fill_in "medical_record_weight", with: 75.0
    fill_in "medical_record_height", with: 180.0
    fill_in "medical_record_heart_rate", with: 75
    fill_in "medical_record_temperature", with: 36.8
    fill_in "medical_record_blood_pressure_systolic", with: 125
    fill_in "medical_record_blood_pressure_diastolic", with: 85
    fill_in "medical_record_diagnosis", with: "Test diagnosis"
    fill_in "medical_record_medications", with: "Test medications"
    fill_in "medical_record_allergies", with: "Test allergies"
    fill_in "medical_record_notes", with: "Test notes"
    click_on "Create Medical record"

    assert_text "Medical record was successfully created"
    click_on "Back"
  end

  test "should update Medical record" do
    visit medical_record_url(@medical_record)
    click_on "Edit this medical record", match: :first

    fill_in "medical_record_weight", with: 72.0
    fill_in "medical_record_diagnosis", with: "Updated diagnosis"
    click_on "Update Medical record"

    assert_text "Medical record was successfully updated"
    click_on "Back"
  end

  test "should destroy Medical record" do
    visit medical_record_url(@medical_record)
    click_on "Destroy this medical record", match: :first

    assert_text "Medical record was successfully destroyed"
  end

  test "should upload x_ray image when creating medical record" do
    visit medical_records_url
    click_on "New medical record"

    select @patient.full_name, from: "medical_record_patient_id"
    select @appointment.id.to_s, from: "medical_record_appointment_id"
    fill_in "medical_record_diagnosis", with: "X-ray shows normal results"

    attach_file "medical_record_x_ray_image",
                Rails.root.join("test", "fixtures", "files", "test_xray.jpg")

    click_on "Create Medical record"

    assert_text "Medical record was successfully created"
    assert_selector "strong", text: "X-ray Image:"
  end

  test "should upload lab results when creating medical record" do
    visit medical_records_url
    click_on "New medical record"

    select @patient.full_name, from: "medical_record_patient_id"
    select @appointment.id.to_s, from: "medical_record_appointment_id"
    fill_in "medical_record_diagnosis", with: "Lab work ordered"

    attach_file "medical_record_lab_results",
                [ Rails.root.join("test", "fixtures", "files", "lab_result_1.pdf"),
                  Rails.root.join("test", "fixtures", "files", "lab_result_2.pdf") ]

    click_on "Create Medical record"

    assert_text "Medical record was successfully created"
    assert_selector "strong", text: "Lab Results:"
    assert_text "lab_result_1.pdf"
    assert_text "lab_result_2.pdf"
  end

  test "viewing medical record shows x_ray image" do
    @medical_record.x_ray_image.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "test_xray.png")),
      filename: "test_xray.png",
      content_type: "image/png"
    )

    visit medical_record_url(@medical_record)

    assert_selector "strong", text: "X-ray Image:"
    assert_selector "img"
    assert_text "test_xray.png"
    assert_link "Download Full Size"
  end

  test "viewing medical record shows lab results list" do
    @medical_record.lab_results.attach([
      {
        io: File.open(Rails.root.join("test", "fixtures", "files", "lab_result_1.pdf")),
        filename: "lab_result_1.pdf",
        content_type: "application/pdf"
      },
      {
        io: File.open(Rails.root.join("test", "fixtures", "files", "lab_result_2.pdf")),
        filename: "lab_result_2.pdf",
        content_type: "application/pdf"
      }
    ])

    visit medical_record_url(@medical_record)

    assert_selector "strong", text: "Lab Results:"
    assert_text "lab_result_1.pdf"
    assert_text "lab_result_2.pdf"
    assert_link "Download", count: 2
  end

  test "should remove x_ray image via UI" do
    @medical_record.x_ray_image.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "test_xray.jpg")),
      filename: "test_xray.jpg",
      content_type: "image/jpeg"
    )

    visit edit_medical_record_url(@medical_record)

    assert_text "test_xray.jpg"

    accept_confirm do
      click_on "Remove", match: :first
    end

    assert_text "X-ray image is being removed"
  end

  test "should remove lab result via UI" do
    @medical_record.lab_results.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "lab_result_1.pdf")),
      filename: "lab_result_1.pdf",
      content_type: "application/pdf"
    )

    visit edit_medical_record_url(@medical_record)

    assert_text "lab_result_1.pdf"

    accept_confirm do
      click_on "Remove", match: :first
    end

    assert_text "Lab result is being removed"
  end

  test "should edit medical record to add new x_ray" do
    assert_not @medical_record.x_ray_image.attached?

    visit edit_medical_record_url(@medical_record)

    attach_file "medical_record_x_ray_image",
                Rails.root.join("test", "fixtures", "files", "test_xray.png")

    click_on "Update Medical record"

    assert_text "Medical record was successfully updated"

    @medical_record.reload
    assert @medical_record.x_ray_image.attached?
    assert_equal "test_xray.png", @medical_record.x_ray_image.filename.to_s
  end

  test "should replace existing x_ray with new one" do
    @medical_record.x_ray_image.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "test_xray.jpg")),
      filename: "test_xray.jpg",
      content_type: "image/jpeg"
    )

    visit edit_medical_record_url(@medical_record)

    attach_file "medical_record_x_ray_image",
                Rails.root.join("test", "fixtures", "files", "test_xray.png")

    click_on "Update Medical record"

    assert_text "Medical record was successfully updated"

    @medical_record.reload
    assert @medical_record.x_ray_image.attached?
    assert_equal "test_xray.png", @medical_record.x_ray_image.filename.to_s
  end
end
