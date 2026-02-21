require "test_helper"

class MedicalRecordsActiveStorageTenantIsolationTest < ActionDispatch::IntegrationTest
  test "blob keys include tenant prefix when uploading files" do
    file = fixture_file_upload("test_xray.jpg", "image/jpeg")

    post medical_records_url, params: {
      medical_record: {
        patient_id: patients(:one).id,
        appointment_id: appointments(:one).id,
        recorded_at: Time.current,
        diagnosis: "Test with X-ray",
        x_ray_image: file
      }
    }

    assert_response :redirect

    new_record = MedicalRecord.last
    blob_key = new_record.x_ray_image.blob.key

    assert blob_key.start_with?("test-medical-center/"),
           "Expected blob key '#{blob_key}' to start with 'test-medical-center/'"
  end

  test "lab results blob keys include tenant prefix" do
    file1 = fixture_file_upload("lab_result_1.pdf", "application/pdf")
    file2 = fixture_file_upload("lab_result_2.pdf", "application/pdf")

    post medical_records_url, params: {
      medical_record: {
        patient_id: patients(:one).id,
        appointment_id: appointments(:one).id,
        recorded_at: Time.current,
        diagnosis: "Test with lab results",
        lab_results: [ file1, file2 ]
      }
    }

    assert_response :redirect

    new_record = MedicalRecord.last
    blob_keys = new_record.lab_results.map { |lr| lr.blob.key }

    assert_equal 2, blob_keys.count

    blob_keys.each do |key|
      assert key.start_with?("test-medical-center/"),
             "Expected blob key '#{key}' to start with 'test-medical-center/'"
    end
  end
end
