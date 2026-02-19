json.extract! medical_record, :id, :patient_id, :appointment_id, :weight, :height, :heart_rate, :temperature, :bloog_pressure_systolic, :bloog_pressure_diastolic, :diagnosis, :created_at, :updated_at
json.url medical_record_url(medical_record, format: :json)
