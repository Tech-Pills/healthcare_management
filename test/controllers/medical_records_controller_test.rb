require "test_helper"

class MedicalRecordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @medical_record = medical_records(:one)
  end

  test "should get index" do
    get medical_records_url
    assert_response :success
  end

  test "should get new" do
    get new_medical_record_url
    assert_response :success
  end

  test "should create medical_record" do
    assert_difference("MedicalRecord.count") do
      post medical_records_url, params: { medical_record: {
        appointment_id: @medical_record.appointment_id,
        patient_id: @medical_record.patient_id,
        recorded_at: Time.current,
        blood_pressure_diastolic: @medical_record.blood_pressure_diastolic,
        blood_pressure_systolic: @medical_record.blood_pressure_systolic,
        diagnosis: @medical_record.diagnosis,
        heart_rate: @medical_record.heart_rate,
        height: @medical_record.height,
        temperature: @medical_record.temperature,
        weight: @medical_record.weight,
        medications: "Test medication",
        allergies: "None",
        notes: "Test notes"
      } }
    end

    assert_redirected_to medical_record_url(MedicalRecord.last)
  end

  test "should show medical_record" do
    get medical_record_url(@medical_record)
    assert_response :success
  end

  test "should get edit" do
    get edit_medical_record_url(@medical_record)
    assert_response :success
  end

  test "should update medical_record" do
    patch medical_record_url(@medical_record), params: { medical_record: {
      appointment_id: @medical_record.appointment_id,
      patient_id: @medical_record.patient_id,
      recorded_at: @medical_record.recorded_at,
      blood_pressure_diastolic: @medical_record.blood_pressure_diastolic,
      blood_pressure_systolic: @medical_record.blood_pressure_systolic,
      diagnosis: @medical_record.diagnosis,
      heart_rate: @medical_record.heart_rate,
      height: @medical_record.height,
      temperature: @medical_record.temperature,
      weight: @medical_record.weight,
      medications: @medical_record.medications,
      allergies: @medical_record.allergies,
      notes: @medical_record.notes
    } }
    assert_redirected_to medical_record_url(@medical_record)
  end

  test "should destroy medical_record" do
    assert_difference("MedicalRecord.count", -1) do
      delete medical_record_url(@medical_record)
    end

    assert_redirected_to medical_records_url
  end

  test "should create medical_record with x_ray_image" do
    file = fixture_file_upload("test_xray.jpg", "image/jpeg")

    assert_difference("MedicalRecord.count") do
      post medical_records_url, params: {
        medical_record: {
          patient_id: @medical_record.patient_id,
          appointment_id: @medical_record.appointment_id,
          recorded_at: Time.current,
          diagnosis: "Test with X-ray",
          x_ray_image: file
        }
      }
    end

    new_record = MedicalRecord.last
    assert new_record.x_ray_image.attached?
    assert_equal "test_xray.jpg", new_record.x_ray_image.filename.to_s
    assert_redirected_to medical_record_url(new_record)
  end

  test "should create medical_record with lab_results" do
    file1 = fixture_file_upload("lab_result_1.pdf", "application/pdf")
    file2 = fixture_file_upload("lab_result_2.pdf", "application/pdf")

    assert_difference("MedicalRecord.count") do
      post medical_records_url, params: {
        medical_record: {
          patient_id: @medical_record.patient_id,
          appointment_id: @medical_record.appointment_id,
          recorded_at: Time.current,
          diagnosis: "Test with lab results",
          lab_results: [ file1, file2 ]
        }
      }
    end

    new_record = MedicalRecord.last
    assert_equal 2, new_record.lab_results.count
    assert new_record.lab_results.attached?
    assert_redirected_to medical_record_url(new_record)
  end

  test "should create medical_record without attachments" do
    assert_difference("MedicalRecord.count") do
      post medical_records_url, params: {
        medical_record: {
          patient_id: @medical_record.patient_id,
          appointment_id: @medical_record.appointment_id,
          recorded_at: Time.current,
          diagnosis: "Test without attachments"
        }
      }
    end

    new_record = MedicalRecord.last
    assert_not new_record.x_ray_image.attached?
    assert_equal 0, new_record.lab_results.count
    assert_redirected_to medical_record_url(new_record)
  end

  test "should update medical_record to add x_ray_image" do
    medical_record = MedicalRecord.create!(
      patient: patients(:one),
      appointment: appointments(:one),
      recorded_at: Time.current
    )

    assert_not medical_record.x_ray_image.attached?

    file = fixture_file_upload("test_xray.png", "image/png")

    patch medical_record_url(medical_record), params: {
      medical_record: {
        x_ray_image: file
      }
    }

    medical_record.reload
    assert medical_record.x_ray_image.attached?
    assert_equal "test_xray.png", medical_record.x_ray_image.filename.to_s
    assert_redirected_to medical_record_url(medical_record)
  end

  test "should update medical_record to add lab_results" do
    medical_record = MedicalRecord.create!(
      patient: patients(:one),
      appointment: appointments(:one),
      recorded_at: Time.current
    )

    assert_equal 0, medical_record.lab_results.count

    file = fixture_file_upload("lab_result_1.pdf", "application/pdf")

    patch medical_record_url(medical_record), params: {
      medical_record: {
        lab_results: [ file ]
      }
    }

    medical_record.reload
    assert_equal 1, medical_record.lab_results.count
    assert_redirected_to medical_record_url(medical_record)
  end

  test "should purge x_ray_image attachment" do
    @medical_record.x_ray_image.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "test_xray.jpg")),
      filename: "test_xray.jpg",
      content_type: "image/jpeg"
    )

    assert @medical_record.x_ray_image.attached?

    delete purge_attachment_medical_record_url(@medical_record),
           params: { attachment: "x_ray_image" }

    assert_redirected_to medical_record_url(@medical_record)
    assert_match(/X-ray image is being removed/, flash[:notice])
  end

  test "should purge specific lab_result attachment" do
    @medical_record.lab_results.attach([
      {
        io: File.open(Rails.root.join("test", "fixtures", "files", "lab_result_1.pdf")),
        filename: "lab_result_1.pdf",
        content_type: "application/pdf"
      }
    ])

    assert @medical_record.lab_results.attached?
    assert @medical_record.lab_results.count > 0

    blob_id = @medical_record.lab_results.first.blob.id

    delete purge_attachment_medical_record_url(@medical_record),
           params: { attachment: "lab_result", blob_id: blob_id }

    assert_redirected_to medical_record_url(@medical_record)
    assert_match(/Lab result is being removed/, flash[:notice])
  end

  test "purge_attachment returns notice when no attachment to purge" do
    medical_record = MedicalRecord.create!(
      patient: patients(:one),
      appointment: appointments(:one),
      recorded_at: Time.current
    )

    delete purge_attachment_medical_record_url(medical_record),
           params: { attachment: "x_ray_image" }

    assert_redirected_to medical_record_url(medical_record)
  end
end
