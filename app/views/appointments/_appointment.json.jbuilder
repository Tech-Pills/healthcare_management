json.extract! appointment, :id, :practice_id, :patient_id, :provider_id, :scheduled_at, :duration_minutes, :status, :notes, :created_at, :updated_at
json.url appointment_url(appointment, format: :json)
