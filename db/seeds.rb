# Seed file for development

puts "Seeding Healthcare Management System..."

practice = Practice.find_by(license_number: "DEV-001")
if practice
  puts "Found existing practice: #{practice.name}"
else
  practice = Practice.create!(
    name: "Development Clinic",
    address: "123 Dev Street, Test City, ST 12345",
    phone: "(555) 123-4567",
    email: "info@devclinic.com",
    license_number: "DEV-001"
  )
  puts "Created practice: #{practice.name}"
end

tenant_name = practice.slug
puts "Using tenant: #{tenant_name} (automatically created by Practice model)"

# Sample patient data
sample_patients = [
    {
      first_name: "John",
      last_name: "Doe", 
      date_of_birth: 35.years.ago.to_date,
      phone: "(555) 111-1111",
      email: "john.doe@example.com",
      address: "789 Patient St, City, NY 10003",
      emergency_contact_name: "Jane Doe",
      emergency_contact_phone: "(555) 111-1112"
    },
    {
      first_name: "Sarah",
      last_name: "Smith",
      date_of_birth: 28.years.ago.to_date, 
      phone: "(555) 222-2222",
      email: "sarah.smith@example.com",
      address: "321 Health Ave, City, NY 10004",
      emergency_contact_name: "Mike Smith",
      emergency_contact_phone: "(555) 222-2223"
    }
  ]

# Create admin user and staff within practice tenant
ApplicationRecord.with_tenant(tenant_name) do
  admin_user = User.find_or_create_by!(email_address: "admin@example.com") do |u|
    u.password = "password123"
  end
  puts "Created/found admin user: #{admin_user.email_address}"

  staff = Staff.find_or_create_by!(user: admin_user) do |s|
    s.first_name = "Practice"
    s.last_name = "Admin"
    s.role = "admin"
    s.license_number = "ADMIN-#{practice.license_number}"
    s.practice_id = practice.id
  end
  puts "Created/found staff record: #{staff.full_name} (User: #{admin_user.email_address})"
end

puts "  Creating patients..."

# Create patients in PatientsRecord tenant context (separate from ApplicationRecord context)
PatientsRecord.with_tenant(tenant_name) do
  sample_patients.each do |patient_data|
    patient = Patient.find_or_create_by!(
      first_name: patient_data[:first_name],
      last_name: patient_data[:last_name],
      date_of_birth: patient_data[:date_of_birth]
    ) do |p|
      p.phone = patient_data[:phone]
      p.email = patient_data[:email] 
      p.address = patient_data[:address]
      p.emergency_contact_name = patient_data[:emergency_contact_name]
      p.emergency_contact_phone = patient_data[:emergency_contact_phone]
      p.practice_id = practice.id
    end
    puts "    Created/found patient: #{patient.full_name}"
  end
end

# Get patient IDs from PatientsRecord context first
puts "  Creating sample appointments..."
patient_ids = []
PatientsRecord.with_tenant(tenant_name) do
  patient_ids = Patient.limit(2).pluck(:id)
end

# Create appointments in ApplicationRecord tenant context
ApplicationRecord.with_tenant(tenant_name) do
  staff_member = Staff.first
  
  if staff_member && patient_ids.any?
    patient_ids.each_with_index do |patient_id, index|
      appointment = Appointment.find_or_create_by!(
        patient_id: patient_id,
        provider_id: staff_member.id,
        practice_id: practice.id,
        scheduled_at: (index + 1).days.from_now.beginning_of_day + 10.hours
      ) do |apt|
        apt.duration_minutes = 30
        apt.notes = "Initial consultation"
        apt.status = "scheduled"
      end
      puts "    Created appointment: #{appointment.scheduled_at.strftime('%Y-%m-%d %H:%M')} with Dr. #{staff_member.full_name}"
    end
  else
    puts "    No staff or patients found to create appointments"
  end
end

puts ""
puts "Seeding completed!"
puts ""
puts "Login credentials:"
puts "  Email: admin@example.com"
puts "  Password: password123"
puts "  Practice: #{practice.name}" 
puts ""
puts "Console usage:"
puts "  # Global models (not tenanted):"
puts "  Practice.all        # All practices"
puts ""
puts "  # Set tenant context for all models:"
puts "  ApplicationRecord.current_tenant = '#{practice.slug}'"
puts "  PatientsRecord.current_tenant = '#{practice.slug}'"
puts ""
puts "  # Then you can access tenanted models:"
puts "  User.all            # Users in current tenant"
puts "  Staff.all           # Staff in current tenant" 
puts "  Patient.all         # Patients in current tenant (needs PatientsRecord context)"
puts "  Appointment.all     # Appointments in current tenant"
puts ""
puts "  # Practice selection for login:"
puts "  Practice.find_by(slug: '#{practice.slug}')  # Find practice for login"
