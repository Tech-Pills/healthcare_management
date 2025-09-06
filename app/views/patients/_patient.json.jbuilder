json.extract! patient, :id, :first_name, :last_name, :date_of_birth, :gender, :phone, :email, :address, :emergency_contact_name, :emergency_contact_phone, :insurance_provider, :insurance_policy_number, :active, :blood_type, :created_at, :updated_at
json.url patient_url(patient, format: :json)
