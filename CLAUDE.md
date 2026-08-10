# Healthcare Management System - Claude Development Log

## Project Overview
A Rails 8.1 healthcare management system with multi-tenant architecture, authentication, practices, staff, patient management, and medical records with Active Storage file attachments.

## Authentication System
- **Rails Authentication Generator**: `rails g authentication`
- **Models**: User, Session
- **Controllers**: SessionsController, PasswordsController
- **Authentication Concern**: Global authentication with test environment bypass
- **Test Configuration**: Authentication automatically skipped in test environment

### Key Authentication Features:
- Session-based authentication with signed cookies
- Password reset functionality via email
- Current.session for request-scoped session management
- Test helpers for both controller and system tests

## Models & Relationships

### User Model
```ruby
class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  # Associations (User and Staff are both in tenant DB)
  has_one :staff
  has_one :practice, through: :staff, disable_joins: true  # Cross-database!

  # Delegations for easy access
  delegate :full_name, :role, :active?, to: :staff, allow_nil: true

  def staff?
    staff.present?
  end
end
```

### Practice Model
```ruby
class Practice < GlobalRecord
  # Validations
  validates :name, :address, :phone, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :license_number, presence: true, uniqueness: true

  # Cross-database associations using standard Rails patterns
  # ActiveRecord routes queries through the target model's connection (tenant DB)
  has_many :staffs, class_name: "Staff", foreign_key: :practice_id
  has_many :patients, class_name: "Patient", foreign_key: :practice_id
  has_many :appointments, class_name: "Appointment", foreign_key: :practice_id
  has_many :users, through: :staffs  # has_many :through works across databases!
end
```

### Staff Model
```ruby
class Staff < ApplicationRecord
  belongs_to :practice, optional: true
  belongs_to :user, optional: true

  validates :practice_id, presence: true
  validates :user_id, presence: true

  enum :role, {
    admin: "admin",
    doctor: "doctor",
    nurse: "nurse",
    receptionist: "receptionist",
    lab_tech: "lab_tech",
    manager: "manager"
  }

  def full_name
    [first_name, last_name].compact.join(' ')
  end

  def medical_staff?
    doctor? || nurse?
  end

  def can_manage_practice?
    admin? || manager?
  end
end
```

### Patient Model
```ruby
class Patient < ApplicationRecord
  belongs_to :practice, optional: true

  validates :practice_id, presence: true

  enum :blood_type, {
    a_positive: "A+", a_negative: "A-",
    b_positive: "B+", b_negative: "B-",
    ab_positive: "AB+", ab_negative: "AB-",
    o_positive: "O+", o_negative: "O-"
  }, prefix: true

  def full_name
    [first_name, last_name].compact.join(' ')
  end
end
```

### MedicalRecord Model
```ruby
class MedicalRecord < ApplicationRecord
  belongs_to :patient
  belongs_to :appointment

  # Active Storage attachments
  has_one_attached :x_ray_image
  has_many_attached :lab_results

  validates :recorded_at, presence: true
  validates :weight, :height, numericality: { greater_than: 0 }, allow_nil: true
  validates :heart_rate, numericality: { greater_than: 0, less_than: 300 }, allow_nil: true
  validates :temperature, numericality: { greater_than: 0, less_than: 50 }, allow_nil: true

  def blood_pressure
    return nil unless blood_pressure_systolic && blood_pressure_diastolic
    "#{blood_pressure_systolic}/#{blood_pressure_diastolic}"
  end

  def practice
    patient.practice
  end
end
```

## Multi-Tenancy Architecture

This application uses the **activerecord-tenanted** gem for subdomain-based multi-tenancy:

### Key Concepts
- **Tenant Isolation**: Each medical practice is a separate tenant with isolated data
- **Subdomain-based**: Tenants are identified by subdomain (e.g., `clinic-1.app.com`)
- **Automatic Tenant Resolution**: Middleware automatically sets the current tenant from the subdomain
- **Database Sharding**: Each tenant has its own database for complete data isolation

### Configuration
```ruby
# config/initializers/active_record_tenanted.rb
Rails.application.config.active_record_tenanted.default_tenant = "test-medical-center" # For tests
Rails.application.config.active_record_tenanted.migrate_tenant_missing_tables = true
```

### Testing with Tenants
- **Test Environment**: Always use default tenant `"test-medical-center"`
- **Multiple Tenants**: Requires separate tenant databases (use demo scripts in `tmp/`)
- **Cross-tenant Isolation**: Cannot be fully tested in test environment without multiple databases

### Active Storage Tenant Isolation
- **Blob Keys**: Automatically prefixed with tenant name (e.g., `test-medical-center/abc123...`)
- **File Isolation**: Each tenant's uploads are stored in separate directories
- **Automatic**: No code changes needed, handled by activerecord-tenanted integration

### Cross-Database Associations

With multi-tenant architecture, models exist in different databases:
- **Global DB**: Practice, Session (via GlobalRecord)
- **Tenant DBs**: User, Staff, Patient, Appointment, MedicalRecord (via ApplicationRecord)

#### belongs_to Associations Across Databases

ActiveRecord `belongs_to` associations work across different database connections:

```ruby
# Tenanted model referencing global model
class Patient < ApplicationRecord
  belongs_to :practice, optional: true  # Practice is in global DB
  validates :practice_id, presence: true
end

# Tenanted model referencing another tenanted model
class Staff < ApplicationRecord
  belongs_to :practice, optional: true  # Global DB
  belongs_to :user, optional: true      # Same tenant DB
  validates :practice_id, presence: true
  validates :user_id, presence: true
end
```

#### Why `optional: true`?

Since Rails 5, `belongs_to` validates presence by default, which queries the database:
- **Without `optional: true`**: Rails validates record exists (queries DB on every save)
- **With `optional: true`**: Skips automatic validation (use custom `validates :practice_id, presence: true` instead)

Benefits of `optional: true` with custom validation:
- ✅ No unnecessary cross-database queries during validation
- ✅ Faster performance (no DB hit to check existence)
- ✅ More flexible (allows orphaned records for reporting)
- ✅ Explicit business rules via `validates :practice_id, presence: true`

#### What Works
- ✅ Simple association access: `patient.practice`
- ✅ Eager loading: `Patient.includes(:practice)`
- ✅ Preload: `Patient.preload(:practice)`
- ✅ Eager load: `Patient.eager_load(:practice)`
- ✅ Query by FK: `Patient.where(practice_id: 1)`
- ✅ Association methods: `patient.association(:practice).reload`

#### What to Avoid
- ❌ Joins: `Patient.joins(:practice)` (queries non-existent table in tenant DB)
- ❌ Nested where: `Patient.where(practice: { name: "X" })` (tries to JOIN)

#### Reverse Associations from Global Models

Global models (Practice) CAN use standard `has_many` associations:

```ruby
class Practice < GlobalRecord
  has_many :staffs, class_name: "Staff", foreign_key: :practice_id
  has_many :patients, class_name: "Patient", foreign_key: :practice_id
  has_many :appointments, class_name: "Appointment", foreign_key: :practice_id
end
```

**How It Works:**
ActiveRecord routes the `has_many` query through the **target model's connection** (Patient's tenant DB), not the owner model's connection (Practice's global DB). This is handled automatically by the activerecord-tenanted gem.

**Evidence:**
- Practice connection: `storage/development_global.sqlite3` (global DB)
- Patient connection: `storage/development/development-clinic.sqlite3` (tenant DB)
- `practice.patients` query executes on **tenant DB** (verified via SQL query logs)
- Works correctly in both test and production environments

**Advanced: :through associations with disable_joins**

✅ **Works:** Practice → Users (both Staff and User in tenant DB)
```ruby
has_many :users, through: :staffs  # ✅ No JOIN needed
```

✅ **Works with disable_joins:** User → Practice (avoids cross-database JOIN)
```ruby
has_one :practice, through: :staff, disable_joins: true  # ✅ Two separate queries!
```

**Why disable_joins is needed for cross-database :through:**

Without `disable_joins: true`:
- Rails tries: `SELECT practices.* FROM practices INNER JOIN staffs ...` ❌
- Fails because staffs table doesn't exist in global database ❌

With `disable_joins: true`:
- Query 1: `SELECT staffs.* FROM staffs WHERE user_id = ?` (tenant DB) ✅
- Query 2: `SELECT practices.* FROM practices WHERE id = ?` (global DB) ✅
- Two separate queries = no cross-database JOIN! ✅

**When to use disable_joins:**
- ✅ Cross-database `has_one :through` or `has_many :through`
- ✅ When you want to avoid JOINs for performance
- ❌ Not needed when both models are in same database

See [CROSS_DATABASE_ASSOCIATIONS_REPORT.md](CROSS_DATABASE_ASSOCIATIONS_REPORT.md) for detailed analysis.

## Active Storage Setup

### Configuration
```ruby
# config/environments/test.rb
config.active_storage.service = :test
config.active_storage.variant_processor = :mini_magick

# config/storage.yml
test:
  service: Disk
  root: <%= Rails.root.join("tmp/storage") %>

test_fixtures:
  service: Disk
  root: <%= Rails.root.join("tmp/storage_fixtures") %>
```

### System Dependencies
- **ImageMagick**: Required for image processing and variants
  ```bash
  # Local development (macOS)
  brew install imagemagick

  # CI/CD (Ubuntu/Debian) - already configured in .github/workflows/ci.yml
  sudo apt-get update && sudo apt-get install -y imagemagick
  ```

### Medical Record Attachments
- **X-ray Images**: Single image attachment (`has_one_attached :x_ray_image`)
- **Lab Results**: Multiple PDF attachments (`has_many_attached :lab_results`)
- **Variants**: X-rays displayed with `resize_to_limit: [600, 600]` variant in views
- **Purging**: Async deletion with `purge_later` via background jobs

### Controller Actions
```ruby
# Purge attachment route
delete :purge_attachment, on: :member

# Controller action
def purge_attachment
  attachment_name = params[:attachment]

  if attachment_name == "x_ray_image" && @medical_record.x_ray_image.attached?
    @medical_record.x_ray_image.purge_later
    redirect_to @medical_record, notice: "X-ray image is being removed."
  elsif attachment_name == "lab_result" && params[:blob_id]
    blob = @medical_record.lab_results.find { |lr| lr.blob.id == params[:blob_id].to_i }
    blob&.purge_later
    redirect_to @medical_record, notice: "Lab result is being removed."
  end
end
```

## Database Schema
- **Users**: email_address, password_digest
- **Sessions**: user_id, user_agent, ip_address
- **Practices**: name, address, phone, email, license_number, active
- **Staffs**: user_id, practice_id, first_name, last_name, role, license_number, active
- **Patients**: practice_id, first_name, last_name, date_of_birth, gender, phone, email, address, emergency contacts, insurance info, blood_type, active
- **MedicalRecords**: patient_id, appointment_id, recorded_at, weight, height, heart_rate, temperature, blood_pressure_systolic, blood_pressure_diastolic, diagnosis, medications, allergies, notes
- **ActiveStorage**: blobs (tenant-scoped keys), attachments (polymorphic associations)

## Controllers & Routes
```ruby
# routes.rb
root "practices#index"
resources :practices
resources :staffs  
resources :patients
resource :session
resources :passwords, param: :token
```

All controllers inherit authentication from ApplicationController with automatic test environment bypass.

## Testing Setup

### Test Authentication
- **Controller Tests**: Use `sign_in_as(users(:one))` helper
- **System Tests**: Authentication bypassed globally in test environment
- **Fixtures**: Users with BCrypt password digest for "password"

### Test Structure
- **Unit Tests**: Model validations, associations, and custom methods
- **Controller Tests**: CRUD operations with authentication
- **Integration Tests**: Cross-layer testing (e.g., tenant isolation)
- **System Tests**: Full UI workflow testing with Capybara/Selenium

### Active Storage Testing Patterns

#### Test Fixture Files
Create minimal valid files in `test/fixtures/files/`:
```bash
# Create test images using ImageMagick
convert -size 10x10 xc:white test/fixtures/files/test_xray.png
convert -size 10x10 xc:white test/fixtures/files/test_xray.jpg

# Create test PDFs (manually or using tools)
# lab_result_1.pdf, lab_result_2.pdf
```

#### Model Tests
**IMPORTANT**: Use `File.open` in model tests, NOT `fixture_file_upload`:
```ruby
test "can attach x_ray_image programmatically" do
  medical_record = MedicalRecord.create!(
    patient: patients(:one),
    appointment: appointments(:one),
    recorded_at: Time.current
  )

  medical_record.x_ray_image.attach(
    io: File.open(Rails.root.join("test", "fixtures", "files", "test_xray.jpg")),
    filename: "test_xray.jpg",
    content_type: "image/jpeg"
  )

  assert medical_record.x_ray_image.attached?
  assert_equal "test_xray.jpg", medical_record.x_ray_image.filename.to_s
  assert_equal "image/jpeg", medical_record.x_ray_image.content_type
end

test "x_ray blob key includes tenant prefix" do
  # Uses default tenant: "test-medical-center"
  medical_record = MedicalRecord.create!(...)
  medical_record.x_ray_image.attach(...)

  blob_key = medical_record.x_ray_image.blob.key
  assert blob_key.start_with?("test-medical-center/")
end
```

#### Controller Tests
Use `fixture_file_upload` helper in controller/integration tests:
```ruby
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
  assert_redirected_to medical_record_url(new_record)
end

test "should purge x_ray_image attachment" do
  @medical_record.x_ray_image.attach(...)
  assert @medical_record.x_ray_image.attached?

  delete purge_attachment_medical_record_url(@medical_record),
         params: { attachment: "x_ray_image" }

  assert_redirected_to medical_record_url(@medical_record)
  assert_match(/X-ray image is being removed/, flash[:notice])
end
```

#### System Tests
Use Capybara's `attach_file` and `accept_confirm` for JavaScript dialogs:
```ruby
test "should upload x_ray image when creating medical record" do
  visit medical_records_url
  click_on "New medical record"

  select @patient.full_name, from: "medical_record_patient_id"
  attach_file "medical_record_x_ray_image",
              Rails.root.join("test", "fixtures", "files", "test_xray.jpg")

  click_on "Create Medical record"
  assert_text "Medical record was successfully created"
end

test "should remove x_ray image via UI" do
  @medical_record.x_ray_image.attach(...)
  visit edit_medical_record_url(@medical_record)

  # Accept confirmation dialog for remove button
  accept_confirm do
    click_on "Remove", match: :first
  end

  assert_text "X-ray image is being removed"
end

test "viewing medical record shows x_ray image" do
  @medical_record.x_ray_image.attach(...)
  visit medical_record_url(@medical_record)

  assert_selector "strong", text: "X-ray Image:"
  assert_selector "img" # Image tag present
  assert_link "Download Full Size"
end
```

#### Integration Tests
Test tenant isolation for uploaded files:
```ruby
test "blob keys include tenant prefix when uploading files" do
  # Uses default tenant: "test-medical-center"
  file = fixture_file_upload("test_xray.jpg", "image/jpeg")

  post medical_records_url, params: {
    medical_record: { ..., x_ray_image: file }
  }

  new_record = MedicalRecord.last
  blob_key = new_record.x_ray_image.blob.key

  assert blob_key.start_with?("test-medical-center/")
end
```

### Test Cleanup Configuration
Essential to prevent test file accumulation:

```ruby
# test/test_helper.rb
module ActiveSupport
  class TestCase
    def after_teardown
      super
      FileUtils.rm_rf(ActiveStorage::Blob.service.root) if ActiveStorage::Blob.service.respond_to?(:root)
    end
  end
end

class ActionDispatch::IntegrationTest
  def after_teardown
    super
    FileUtils.rm_rf(ActiveStorage::Blob.service.root) if ActiveStorage::Blob.service.respond_to?(:root)
  end
end

Minitest.after_run do
  FileUtils.rm_rf(ActiveStorage::Blob.services.fetch(:test_fixtures).root)
end

# test/application_system_test_case.rb
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  def after_teardown
    super
    FileUtils.rm_rf(ActiveStorage::Blob.service.root) if ActiveStorage::Blob.service.respond_to?(:root)
  end
end
```

### Testing Best Practices

1. **Code Style**:
   - DO NOT add comments to test code
   - Test names should be self-explanatory
   - Keep tests concise and readable

2. **File Upload Helpers**:
   - Model tests: Use `File.open(Rails.root.join(...))`
   - Controller/Integration tests: Use `fixture_file_upload("filename", "mime/type")`
   - System tests: Use `attach_file "field_name", Rails.root.join(...)`

3. **ActiveStorage::Attached Methods**:
   - `has_one_attached`: Use `.attached?` to check, returns boolean
   - `has_many_attached`: Use `.attached?` (NOT `.all?(&:attached?)`), returns boolean
   - Use `.count` for collection size, not `.length` or `.size`

4. **Tenant Testing**:
   - Always use default tenant `"test-medical-center"` in test environment
   - Verify blob keys start with tenant prefix
   - Cross-tenant isolation requires multiple tenant databases (use demo scripts)

5. **JavaScript Interactions**:
   - Use `accept_confirm { ... }` for confirmation dialogs
   - Use `dismiss_confirm { ... }` if testing cancellation

6. **Image Variants**:
   - Requires ImageMagick installed (`brew install imagemagick`)
   - Configure variant processor in test environment
   - Test files must be valid images (use ImageMagick to create them)

7. **Common Assertions**:
   - `assert record.attachment.attached?`
   - `assert_equal "filename.jpg", record.attachment.filename.to_s`
   - `assert_equal "image/jpeg", record.attachment.content_type`
   - `assert_equal 2, record.attachments.count`
   - `assert blob_key.start_with?("tenant-name/")`

## Action Cable Real-Time Notifications

This application implements Action Cable for real-time appointment notifications with automatic tenant isolation. When appointments are created, updated, or destroyed, staff members viewing the practice dashboard receive instant toast notifications.

### Architecture Overview

- **SolidCable**: Rails 8 default cable adapter using SQLite
- **Tenant-Scoped Streams**: Automatic isolation using `stream_for practice`
- **Global ID Integration**: Records include tenant parameter in stream names
- **Broadcast Callbacks**: `after_commit` hooks for reliable real-time updates

### Configuration

```ruby
# config/cable.yml (Rails 8 default)
development:
  adapter: solid_cable
  connects_to:
    database:
      writing: cable

test:
  adapter: test

# config/importmap.rb
pin "@rails/actioncable", to: "actioncable.esm.js"
pin_all_from "app/javascript/channels", under: "channels"

# app/javascript/application.js
import "channels"
```

### Connection Setup

**CRITICAL**: Always call `super` first in `ApplicationCable::Connection#connect`:

```ruby
# app/channels/application_cable/connection.rb
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      super  # ⚠️ REQUIRED for tenant context!
      set_current_user || reject_unauthorized_connection
    end

    private

    def set_current_user
      if authenticated?
        self.current_user = Current.user
      end
    end
  end
end
```

Without `super`, the activerecord-tenanted gem's tenant resolution won't run, breaking all tenant isolation.

### Channel Implementation

```ruby
# app/channels/application_cable/channel.rb
module ApplicationCable
  class Channel < ActionCable::Channel::Base
  end
end

# app/channels/appointment_channel.rb
class AppointmentChannel < ApplicationCable::Channel
  def subscribed
    practice = current_user.staff.practice
    stream_for practice  # Automatically tenant-scoped!
  end

  def unsubscribed
  end
end
```

The `stream_for practice` call automatically creates tenant-specific stream names like:
- `appointment:Z2lkOi8vYXBwL1ByYWN0aWNlLzE/dGVuYW50PXRlc3QtbWVkaWNhbC1jZW50ZXI`

This Global ID includes the tenant parameter, ensuring complete isolation.

### Model Broadcast Callbacks

```ruby
# app/models/appointment.rb
class Appointment < ApplicationRecord
  after_create_commit :broadcast_appointment_created
  after_update_commit :broadcast_appointment_updated
  after_destroy_commit :broadcast_appointment_destroyed

  private

  def broadcast_appointment_created
    broadcast_appointment_change("created")
  end

  def broadcast_appointment_updated
    broadcast_appointment_change("updated")
  end

  def broadcast_appointment_destroyed
    broadcast_appointment_change("destroyed")
  end

  def broadcast_appointment_change(action)
    AppointmentChannel.broadcast_to(
      practice,
      {
        action: action,
        appointment: {
          id: id,
          patient_name: patient.full_name,
          provider_name: provider.full_name,
          scheduled_at: scheduled_at.strftime("%B %d, %Y at %I:%M %p"),
          status: status,
          duration_minutes: duration_minutes
        }
      }
    )
  end
end
```

**Why `after_commit`?** Ensures database transaction completes before broadcasting, preventing race conditions.

### JavaScript Consumer

```javascript
// app/javascript/channels/consumer.js
import { createConsumer } from "@rails/actioncable"

export default createConsumer()

// app/javascript/channels/index.js
import "./appointment_channel"

// app/javascript/channels/appointment_channel.js
import consumer from "./consumer"

consumer.subscriptions.create("AppointmentChannel", {
  connected() {
    console.log("Connected to AppointmentChannel")
  },

  disconnected() {
    console.log("Disconnected from AppointmentChannel")
  },

  received(data) {
    console.log("Received appointment notification:", data)
    this.showNotification(data)
  },

  showNotification(data) {
    const { action, appointment } = data
    const container = document.getElementById("toast-container")
    if (!container) return

    const toast = document.createElement("div")
    toast.className = `toast toast-${action}`

    toast.innerHTML = `
      <div class="toast-header">
        <strong>Appointment ${action.charAt(0).toUpperCase() + action.slice(1)}</strong>
        <button class="toast-close" onclick="this.closest('.toast').remove()">×</button>
      </div>
      <div class="toast-body">
        <p><strong>${appointment.patient_name}</strong> with ${appointment.provider_name}</p>
        <small>${appointment.scheduled_at} (${appointment.duration_minutes} min)</small>
      </div>
    `

    container.appendChild(toast)

    setTimeout(() => toast.classList.add("show"), 10)
    setTimeout(() => {
      toast.classList.remove("show")
      setTimeout(() => toast.remove(), 300)
    }, 5000)
  }
})
```

### UI Components

```html
<!-- app/views/layouts/application.html.erb -->
<body>
  <div id="toast-container"></div>
  <!-- rest of layout -->
</body>
```

```css
/* app/assets/stylesheets/application.css */
#toast-container {
  position: fixed;
  top: 20px;
  right: 20px;
  z-index: 9999;
  display: flex;
  flex-direction: column;
  gap: 10px;
  max-width: 400px;
}

.toast {
  background: white;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  transform: translateX(450px);
  transition: transform 0.3s ease-in-out;
}

.toast.show {
  transform: translateX(0);
}

.toast-created .toast-header {
  background-color: #d4edda;
  color: #155724;
}

.toast-updated .toast-header {
  background-color: #d1ecf1;
  color: #0c5460;
}

.toast-destroyed .toast-header {
  background-color: #fff3cd;
  color: #856404;
}
```

### Testing Action Cable

#### Channel Tests

```ruby
# test/channels/appointment_channel_test.rb
require "test_helper"

class AppointmentChannelTest < ActionCable::Channel::TestCase
  setup do
    @practice = practices(:one)
    @user = users(:one)
    @staff = staffs(:admin)

    @user.update!(staff: @staff)
    @staff.update!(practice_id: @practice.id)
  end

  test "subscribes to practice stream" do
    stub_connection current_user: @user

    subscribe

    assert subscription.confirmed?
    assert_has_stream_for @practice
  end

  test "rejects subscription without authenticated user" do
    stub_connection current_user: nil

    assert_raises(NoMethodError) do
      subscribe
    end
  end

  test "subscribes only to own practice stream" do
    other_practice = practices(:two)
    stub_connection current_user: @user

    subscribe

    assert_has_stream_for @practice
    refute_has_stream_for other_practice
  end
end
```

#### Integration Tests

```ruby
# test/integration/appointment_notifications_test.rb
require "test_helper"

class AppointmentNotificationsTest < ActionDispatch::IntegrationTest
  include ActionCable::TestHelper

  setup do
    @practice_one = practices(:one)
    @practice_two = practices(:two)
    @staff_one = staffs(:admin)
    @patient_one = patients(:one)
  end

  test "broadcasts appointment creation to practice stream" do
    stream = AppointmentChannel.broadcasting_for(@practice_one)

    assert_broadcasts(stream, 1) do
      Appointment.create!(
        practice_id: @practice_one.id,
        patient_id: @patient_one.id,
        provider_id: @staff_one.id,
        scheduled_at: 1.day.from_now,
        duration_minutes: 30,
        status: "scheduled"
      )
    end
  end

  test "tenant isolation: practice one broadcasts only to practice one stream" do
    stream_one = AppointmentChannel.broadcasting_for(@practice_one)
    stream_two = AppointmentChannel.broadcasting_for(@practice_two)

    assert_broadcasts(stream_one, 1) do
      assert_no_broadcasts(stream_two) do
        Appointment.create!(
          practice_id: @practice_one.id,
          patient_id: @patient_one.id,
          provider_id: @staff_one.id,
          scheduled_at: 1.day.from_now,
          duration_minutes: 30,
          status: "scheduled"
        )
      end
    end
  end

  test "broadcast payload includes appointment details" do
    stream = AppointmentChannel.broadcasting_for(@practice_one)

    messages = capture_broadcasts(stream) do
      Appointment.create!(
        practice_id: @practice_one.id,
        patient_id: @patient_one.id,
        provider_id: @staff_one.id,
        scheduled_at: 1.day.from_now,
        duration_minutes: 30,
        status: "scheduled"
      )
    end

    assert_equal 1, messages.length
    assert_equal "created", messages.first["action"]
    assert_includes messages.first.keys, "appointment"
  end
end
```

### Action Cable Testing Best Practices

1. **Include ActionCable::TestHelper**: Required for broadcast assertions
2. **Channel Tests**: Use `ActionCable::Channel::TestCase` for subscription tests
3. **Integration Tests**: Use `ActionDispatch::IntegrationTest` with `ActionCable::TestHelper`
4. **Assertion Methods**:
   - `assert_broadcasts(stream, number) { }` - Verify broadcast count
   - `assert_no_broadcasts(stream) { }` - Verify no broadcasts
   - `capture_broadcasts(stream) { }` - Capture and inspect broadcast payloads
   - `assert_has_stream_for(record)` - Verify channel subscription (channel tests only)

5. **Tenant Isolation Testing**:
   - Create appointments in different practices
   - Verify broadcasts only go to correct practice stream
   - Use `AppointmentChannel.broadcasting_for(practice)` to get stream name
   - Confirm Global ID includes tenant parameter

### How Tenant Isolation Works

1. **Global ID with Tenant**: When `stream_for practice` is called, the gem creates a Global ID like:
   ```
   gid://app/Practice/1?tenant=test-medical-center
   ```

2. **Unique Stream Names**: Each tenant's practice gets a unique stream name:
   - Tenant A Practice 1: `appointment:Z2lkOi8vYXBwL1ByYWN0aWNlLzE/dGVuYW50PWE`
   - Tenant B Practice 1: `appointment:Z2lkOi8vYXBwL1ByYWN0aWNlLzE/dGVuYW50PWI`

3. **Automatic Isolation**: Even with same Practice ID, different tenants get different streams!

4. **No Cross-Tenant Leakage**: Broadcasts to Tenant A's stream never reach Tenant B's subscribers

## Key Features Implemented

### 1. Authentication & Authorization
- Session-based login/logout
- Password reset via email
- Role-based staff permissions
- Test environment authentication bypass

### 2. Multi-Tenancy (activerecord-tenanted)
- Subdomain-based tenant identification
- Database sharding for complete data isolation
- Automatic tenant resolution from subdomain
- Tenant-scoped Active Storage file uploads
- Practice-based tenant architecture

### 3. Practice Management
- CRUD operations for medical practices
- License number uniqueness validation
- Staff and patient associations
- Tenant database per practice

### 4. Staff Management
- User account linking
- Role-based permissions (admin, doctor, nurse, etc.)
- Practice association
- Medical staff identification

### 5. Patient Management
- Practice association (required)
- Blood type enum with prefix
- Emergency contact information
- Insurance details
- Form with practice selection dropdown

### 6. Medical Records with Active Storage
- Patient and appointment associations
- Vital signs tracking (weight, height, heart rate, temperature, blood pressure)
- Diagnosis, medications, allergies, and notes fields
- **X-ray Image Upload**: Single image attachment with thumbnail variants
- **Lab Results Upload**: Multiple PDF file attachments
- **File Management**: View, download, and remove attachments via UI
- **Tenant-Scoped Storage**: Files automatically isolated by tenant
- **Background Job Processing**: Async file deletion with `purge_later`

### 7. Real-Time Notifications with Action Cable
- Instant appointment notifications for create/update/destroy events
- Tenant-scoped WebSocket streams using `stream_for practice`
- Toast notification UI with color-coded actions (green=created, blue=updated, yellow=destroyed)
- Global ID integration for automatic tenant isolation
- SolidCable adapter (Rails 8 default with SQLite)
- Comprehensive channel and integration tests
- No cross-tenant leakage: Practice A never sees Practice B's notifications

## Development Commands Used
```bash
# Generate authentication
rails g authentication

# Generate scaffolds
rails g scaffold Practice name:string address:string phone:string email:string license_number:string active:boolean
rails g scaffold Staff user:references practice:references first_name:string last_name:string role:string license_number:string active:boolean
rails g scaffold Patient practice:references first_name:string last_name:string date_of_birth:date gender:string phone:string email:string address:text emergency_contact_name:text emergency_contact_phone:text insurance_provider:string insurance_policy_number:string active:boolean blood_type:string
rails g scaffold MedicalRecord patient:references appointment:references recorded_at:datetime weight:decimal height:decimal heart_rate:integer temperature:decimal blood_pressure_systolic:integer blood_pressure_diastolic:integer diagnosis:text medications:text allergies:text notes:text

# Install system dependencies
brew install imagemagick      # Required for Active Storage image processing

# Run tests
rails test                    # All tests
rails test:system            # System tests only
rails test test/models/      # Model tests only
rails test test/controllers/ # Controller tests only
rails test test/integration/ # Integration tests only

# Run specific test files
rails test test/models/medical_record_test.rb
rails test test/controllers/medical_records_controller_test.rb
rails test:system test/system/medical_records_test.rb
rails test test/integration/medical_records_active_storage_tenant_isolation_test.rb

# Create test fixture files
convert -size 10x10 xc:white test/fixtures/files/test_xray.png
convert -size 10x10 xc:white test/fixtures/files/test_xray.jpg

# Seed database with sample data
rails db:seed                 # Create practices, staff, patients, appointments, and medical records with attachments

# Test CI workflows locally with act
brew install act              # Install act (requires Docker)
act -l                        # List all workflows and jobs
act -j test                   # Run only the test job
act -j system-test            # Run only the system-test job
act -n                        # Dry run (shows what would execute)
```

## Testing CI Locally

Use **[act](https://github.com/nektos/act)** to run GitHub Actions workflows locally before pushing:

### Installation
```bash
brew install act
```

**Requirements**: Docker must be running

### Usage
```bash
# List all available jobs
act -l

# Run all workflows (dry run)
act -n

# Run specific jobs
act -j test                  # Run unit/integration tests
act -j system-test           # Run system tests
act -j lint                  # Run RuboCop
act -j scan_ruby            # Run Brakeman security scan

# Run for specific events
act push                     # Simulate push to main
act pull_request            # Simulate pull request
```

### Configuration
The [.actrc](.actrc) file contains default settings:
- Uses `catthehacker/ubuntu:act-latest` Docker image
- Enables container reuse for faster runs
- Sets verbose output for debugging

### Common Issues
- **First run is slow**: Docker images are large (~500MB-18GB)
- **Container reuse**: Speeds up subsequent runs with `--reuse` flag
- **Platform issues**: Uses `linux/amd64` architecture for compatibility

## Seed Data

The seed file (`db/seeds.rb`) creates comprehensive sample data for development:

### Sample Files Location
- **Directory**: `db/seed_files/`
- **X-ray Images**: `sample_xray.png`, `sample_xray_2.jpg`
- **Lab Results**: `sample_lab_result_1.pdf`, `sample_lab_result_2.pdf`

### What Gets Seeded
For each of 3 practices (Development Clinic, Metro Health Center, Sunset Medical Group):
1. **Practice**: Medical practice with license number and contact info
2. **Admin User**: `admin@example.com` / `password123`
3. **Staff**: Practice admin linked to user
4. **Patients**: 2 patients per practice with demographics
5. **Appointments**: 2 scheduled appointments
6. **Medical Records with Attachments**:
   - First patient: Medical record with X-ray image attached
   - Second patient: Medical record with 2 lab result PDFs attached
   - Includes vitals (weight, height, heart rate, temperature, blood pressure)
   - Includes diagnosis, medications, allergies, and notes

### Verifying Seed Data
```bash
# In Rails console
ApplicationRecord.current_tenant = 'development-clinic'

# Check medical records
MedicalRecord.all.count  # Should show 2 records

# Check attachments
mr = MedicalRecord.first
mr.x_ray_image.attached?                 # true
mr.x_ray_image.filename                  # xray_developer_20260221.png
mr.x_ray_image.blob.key                  # development-clinic/abc123...

mr2 = MedicalRecord.last
mr2.lab_results.count                    # 2
mr2.lab_results.first.filename           # bloodwork_tester_20260221.pdf
mr2.lab_results.first.blob.key           # development-clinic/def456...
```

### Seed File Patterns for Active Storage
```ruby
# Attaching single file (has_one_attached)
medical_record.x_ray_image.attach(
  io: File.open(Rails.root.join("db", "seed_files", "sample_xray.png")),
  filename: "xray_#{patient.last_name.downcase}_#{Date.current.strftime('%Y%m%d')}.png",
  content_type: "image/png"
)

# Attaching multiple files (has_many_attached)
medical_record.lab_results.attach([
  {
    io: File.open(Rails.root.join("db", "seed_files", "sample_lab_result_1.pdf")),
    filename: "bloodwork_#{patient.last_name.downcase}_#{Date.current.strftime('%Y%m%d')}.pdf",
    content_type: "application/pdf"
  },
  {
    io: File.open(Rails.root.join("db", "seed_files", "sample_lab_result_2.pdf")),
    filename: "urinalysis_#{patient.last_name.downcase}_#{Date.current.strftime('%Y%m%d')}.pdf",
    content_type: "application/pdf"
  }
])

# Check if already attached to avoid duplicates
if !medical_record.x_ray_image.attached?
  # attach file...
end

if medical_record.lab_results.count == 0
  # attach files...
end
```

## Test Status
✅ All controller tests passing (including Active Storage uploads)
✅ All model tests passing (including attachment associations and cross-database associations)
✅ All system tests passing (including UI file uploads/removals)
✅ All integration tests passing (including tenant isolation)
✅ All channel tests passing (Action Cable subscription tests)
✅ All Action Cable broadcast tests passing (tenant isolation verified)
✅ Authentication working in all environments
✅ Active Storage file attachments fully tested
✅ Tenant-scoped storage verified
✅ Cross-database associations fully tested

**Total Test Coverage**: 173 runs, 538 assertions, 0 failures, 0 errors

**Model Test Coverage**:
- User model: 14 tests, 44 assertions
- Staff model: 16 tests, 41 assertions
- Practice model: 14 tests, 63 assertions
- Patient model: 16 tests, 70 assertions
- Appointment model: 17 tests, 62 assertions

**Action Cable Test Coverage**:
- AppointmentChannelTest: 3 tests (subscription and isolation)
- AppointmentNotificationsTest: 12 tests, 41 assertions (broadcast integration and tenant isolation)

## Notes for Future Development
- ✅ ~~Consider adding patient medical records~~ (Implemented with Active Storage)
- ✅ ~~Consider multi-tenancy for larger deployments~~ (Implemented with activerecord-tenanted)
- ✅ ~~Implement real-time appointment notifications~~ (Implemented with Action Cable)
- Implement appointment scheduling
- Add staff scheduling/availability
- Add reporting and analytics features
- Implement email notifications for appointments
- Add patient portal for accessing medical records
- Implement audit logging for HIPAA compliance
- Add bulk file uploads for lab results
- Implement medical record sharing between providers