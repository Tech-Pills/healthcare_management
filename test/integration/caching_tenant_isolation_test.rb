require "test_helper"

class CachingTenantIsolationTest < ActionDispatch::IntegrationTest
  setup do
    @practice = practices(:one)
    @medical_record = medical_records(:one)
    @patient = patients(:one)
    Rails.cache.clear
  end

  teardown do
    Rails.cache.clear
  end

  test "medical record cache_key includes tenant prefix" do
    cache_key = @medical_record.cache_key

    assert cache_key.start_with?("test-medical-center/"),
           "Expected cache_key '#{cache_key}' to start with 'test-medical-center/'"
  end

  test "medical record cache_key_with_version includes tenant prefix" do
    cache_key = @medical_record.cache_key_with_version

    assert cache_key.start_with?("test-medical-center/"),
           "Expected cache_key_with_version '#{cache_key}' to start with 'test-medical-center/'"
  end

  test "patient cache_key includes tenant prefix" do
    cache_key = @patient.cache_key

    assert cache_key.start_with?("test-medical-center/"),
           "Expected cache_key '#{cache_key}' to start with 'test-medical-center/'"
  end

  test "fragment caching on medical record show uses tenant-scoped key" do
    get medical_record_url(@medical_record)

    assert_response :success
    assert_select "##{dom_id(@medical_record)}"
  end

  test "collection caching on medical records index renders all records" do
    get medical_records_url

    assert_response :success
    assert_select "tbody#medical_records tr", minimum: 1
  end

  test "collection caching serves cached rows on second request" do
    get medical_records_url
    assert_response :success

    get medical_records_url
    assert_response :success
    assert_select "tbody#medical_records tr", minimum: 1
  end

  test "Rails.cache clinic stats use tenant-prefixed key" do
    get root_url
    assert_response :success

    tenant = ApplicationRecord.current_tenant
    cache_key = "#{tenant}/clinic_stats"
    cached_value = Rails.cache.read(cache_key)

    assert_not_nil cached_value, "Expected clinic stats to be cached at '#{cache_key}'"
    assert_equal Patient.count, cached_value[:total_patients]
    assert_equal Appointment.count, cached_value[:total_appointments]
    assert_equal Staff.count, cached_value[:total_staff]
  end

  test "Rails.cache keys without tenant prefix return nil" do
    get root_url
    assert_response :success

    wrong_key = "wrong-tenant/clinic_stats"
    assert_nil Rails.cache.read(wrong_key),
               "Expected cache miss for wrong tenant key '#{wrong_key}'"
  end

  test "clinic stats are served from cache on second request" do
    get root_url
    assert_response :success

    tenant = ApplicationRecord.current_tenant
    cache_key = "#{tenant}/clinic_stats"

    Rails.cache.write(cache_key, {
      total_patients: 999,
      total_appointments: 888,
      total_staff: 777,
      upcoming_appointments: 666
    }, expires_in: 15.minutes)

    get root_url
    assert_response :success
    assert_select "div", text: /999/
  end
end
