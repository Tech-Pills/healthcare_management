# Seed file for development

puts "Seeding Healthcare Management System..."

# Create three practices for testing multi-tenancy
practices_data = [
  {
    name: "Development Clinic",
    address: "123 Dev Street, Test City, ST 12345",
    phone: "(555) 123-4567",
    email: "info@devclinic.com",
    license_number: "DEV-001"
  },
  {
    name: "Metro Health Center",
    address: "456 Metro Ave, Downtown, NY 10001",
    phone: "(555) 234-5678",
    email: "contact@metrohealth.com",
    license_number: "MHC-002"
  },
  {
    name: "Sunset Medical Group",
    address: "789 Sunset Blvd, West Side, CA 90210",
    phone: "(555) 345-6789",
    email: "hello@sunsetmedical.com",
    license_number: "SMG-003"
  }
]

practices = []
practices_data.each do |practice_data|
  practice = Practice.find_by(license_number: practice_data[:license_number])
  if practice
    puts "Found existing practice: #{practice.name}"
  else
    practice = Practice.create!(practice_data)
    puts "Created practice: #{practice.name}"
  end
  practices << practice
end

patients_by_practice = {
  "development-clinic" => [
    {
      first_name: "Alex",
      last_name: "Developer",
      date_of_birth: 32.years.ago.to_date,
      phone: "(555) 111-1111",
      email: "alex.developer@devclinic.com",
      address: "101 Code Street, Dev City, ST 12345",
      emergency_contact_name: "Jamie Developer",
      emergency_contact_phone: "(555) 111-1112"
    },
    {
      first_name: "Taylor",
      last_name: "Tester",
      date_of_birth: 29.years.ago.to_date,
      phone: "(555) 111-2222",
      email: "taylor.tester@devclinic.com",
      address: "102 Debug Ave, Dev City, ST 12345",
      emergency_contact_name: "Casey Tester",
      emergency_contact_phone: "(555) 111-2223"
    }
  ],
  "metro-health-center" => [
    {
      first_name: "Jordan",
      last_name: "Metro",
      date_of_birth: 28.years.ago.to_date,
      phone: "(555) 234-1111",
      email: "jordan.metro@metrohealth.com",
      address: "500 Downtown Plaza, Metro City, NY 10001",
      emergency_contact_name: "River Metro",
      emergency_contact_phone: "(555) 234-1112"
    },
    {
      first_name: "Sage",
      last_name: "Urban",
      date_of_birth: 35.years.ago.to_date,
      phone: "(555) 234-2222",
      email: "sage.urban@metrohealth.com",
      address: "501 City Center, Metro City, NY 10001",
      emergency_contact_name: "Quinn Urban",
      emergency_contact_phone: "(555) 234-2223"
    }
  ],
  "sunset-medical-group" => [
    {
      first_name: "Phoenix",
      last_name: "Sunset",
      date_of_birth: 31.years.ago.to_date,
      phone: "(555) 345-1111",
      email: "phoenix.sunset@sunsetmedical.com",
      address: "900 Sunset Drive, West Hills, CA 90210",
      emergency_contact_name: "Sky Sunset",
      emergency_contact_phone: "(555) 345-1112"
    },
    {
      first_name: "Ocean",
      last_name: "Coastal",
      date_of_birth: 26.years.ago.to_date,
      phone: "(555) 345-2222",
      email: "ocean.coastal@sunsetmedical.com",
      address: "901 Pacific View, West Hills, CA 90210",
      emergency_contact_name: "Bay Coastal",
      emergency_contact_phone: "(555) 345-2223"
    }
  ]
}

practices.each do |practice|
  tenant_name = practice.slug
  puts "Setting up tenant: #{tenant_name} for #{practice.name}"

  ApplicationRecord.with_tenant(tenant_name) do
    admin_user = User.find_or_create_by!(email_address: "admin@example.com") do |u|
      u.password = "password123"
    end
    puts "  Created/found admin user: #{admin_user.email_address}"

    staff = Staff.find_or_create_by!(user_id: admin_user.id) do |s|
      s.first_name = "Practice"
      s.last_name = "Admin"
      s.role = "admin"
      s.license_number = "ADMIN-#{practice.license_number}"
      s.practice_id = practice.id
    end
    puts "  Created/found staff record: #{staff.full_name} (User: #{admin_user.email_address})"
  end
end

practices.each do |practice|
  tenant_name = practice.slug
  puts "  Creating patients for #{practice.name}..."

  ApplicationRecord.with_tenant(tenant_name) do
    practice_patients = patients_by_practice[tenant_name] || []
    practice_patients.each do |patient_data|
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

    puts "  Creating sample appointments for #{practice.name}..."
    patient_ids = Patient.limit(2).pluck(:id)
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
end

puts ""
puts "Seeding completed!"
puts ""
puts "Login credentials (same for all practices):"
puts "  Email: admin@example.com"
puts "  Password: password123"
puts ""
puts "Available practice domains:"
practices.each do |practice|
  puts "  #{practice.name}: http://#{practice.slug}.localhost:3000"
end
puts ""
puts "Console usage:"
puts "  # Global models (not tenanted):"
puts "  Practice.all        # All practices"
puts ""
puts "  # Set tenant context for specific practice:"
practices.each do |practice|
  puts "  # For #{practice.name}:"
  puts "  ApplicationRecord.current_tenant = '#{practice.slug}'"
  puts ""
end
puts "  # Then you can access tenanted models:"
puts "  User.all            # Users in current tenant"
puts "  Staff.all           # Staff in current tenant"
puts "  Patient.all         # Patients in current tenant"
puts "  Appointment.all     # Appointments in current tenant"
