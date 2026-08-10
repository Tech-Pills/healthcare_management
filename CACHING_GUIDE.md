# Caching with Multi-Tenancy — Study & Testing Guide

This guide covers the four caching types implemented in this project and how the `activerecord-tenanted` gem (v0.6.0) provides automatic tenant isolation for each.

## How the Gem Makes Caching Tenant-Safe

The gem overrides `cache_key` on all tenanted models (`lib/active_record/tenanted/tenant.rb:15-17`):

```ruby
def cache_key
  tenant ? "#{tenant}/#{super}" : super
end
```

This means:
- `MedicalRecord.find(1).cache_key` → `"test-medical-center/medical_records/1"` (not `"medical_records/1"`)
- Two tenants with the same record ID get completely separate cache entries
- Fragment caching, collection caching, and Russian doll caching all benefit automatically

---

## Setup

```bash
# Enable caching in development (toggle on/off)
rails dev:cache

# Start the server
rails s -b 0.0.0.0 -p 3000

# Visit: http://development-clinic.localhost:3000
```

---

## 1. Fragment Caching

**What it does**: Caches the entire rendered HTML of a medical record partial.

**Where**: `app/views/medical_records/_medical_record.html.erb`

```erb
<% cache medical_record do %>
  <div id="<%= dom_id medical_record %>">
    <%# ... all content ... %>
  </div>
<% end %>
```

**How to test locally**:
1. Visit any medical record show page (e.g. `/medical_records/1`)
2. Check Rails server logs — first load shows:
   ```
   Write fragment views/test-medical-center/medical_records/1-2026...
   ```
3. Reload the page — second load shows:
   ```
   Read fragment views/test-medical-center/medical_records/1-2026... (hit)
   ```
   No SQL queries for the cached content.
4. Update the record in console:
   ```ruby
   MedicalRecord.first.touch
   ```
5. Reload — cache miss (new `updated_at` changes the key), fresh SQL + re-render

**Tenant isolation**: The cache key starts with `test-medical-center/` — another tenant's `medical_records/1` would have a completely different key like `other-clinic/medical_records/1`.

---

## 2. Collection Caching

**What it does**: Caches each row in the medical records index table individually. Only changed rows re-render.

**Where**: `app/views/medical_records/index.html.erb`

```erb
<%= render partial: "medical_record_row", collection: @medical_records, cached: true %>
```

**How to test locally**:
1. Visit `/medical_records`
2. First load — logs show `Write fragment` for each row
3. Reload — logs show `Read fragment` (hit) for every row — instant render
4. Update one record:
   ```ruby
   MedicalRecord.first.update!(diagnosis: "Updated diagnosis")
   ```
5. Reload — only the updated row shows a cache miss, all others are hits

**Why this matters for performance**: With 100 medical records, only the 1 you changed re-renders. The other 99 are served from cache.

---

## 3. Russian Doll Caching (Patient → Medical Records)

**What it does**: Wraps multiple medical records inside a patient-level outer cache. When one medical record is updated, the patient's outer cache invalidates and re-renders — but the **unchanged** medical records' inner caches still hit.

**How it works**:
- `MedicalRecord belongs_to :patient, touch: true` — updating a medical record bumps `patient.updated_at`
- Outer cache: `<% cache @patient %>` on the patient show page
- Inner caches: `<% cache medical_record %>` for each individual medical record (already in `_medical_record.html.erb`)

**Where**:
- Outer: `app/views/patients/show.html.erb` — `<% cache @patient %>`
- Inner: `app/views/medical_records/_medical_record.html.erb` — `<% cache medical_record %>`

**Cache keys produced** (for a patient with 3 medical records):
```
test-medical-center/patients/1-20260303...                (outer)
  test-medical-center/medical_records/1-20260301...       (inner - HIT)
  test-medical-center/medical_records/2-20260303...       (inner - MISS, just updated)
  test-medical-center/medical_records/3-20260215...       (inner - HIT)
```

**How to test locally**:
1. Visit a patient show page (e.g. `/patients/1`)
2. Logs show 1 outer `Write fragment` + 1 inner `Write fragment` per medical record
3. Reload — all cache hits (outer + all inner)
4. Update one medical record in console:
   ```ruby
   MedicalRecord.find(2).update!(diagnosis: "Changed diagnosis")
   ```
   This automatically touches the patient (`patient.updated_at` is bumped).
5. Reload — logs show:
   - Outer patient cache: **MISS** (patient's `updated_at` changed)
   - MedicalRecord #1: **HIT** (its `updated_at` didn't change)
   - MedicalRecord #2: **MISS** (its `updated_at` changed)
   - MedicalRecord #3: **HIT** (its `updated_at` didn't change)
6. Result: only 1 of 3 records re-rendered — the other 2 served from cache

**Why this is a proper Russian doll**: The outer key (patient) and inner keys (medical records) depend on **different** `updated_at` timestamps. Updating one child invalidates the parent, but sibling caches survive.

---

## 4. Rails.cache Direct Calls (Manual Tenant Prefix)

**What it does**: Caches clinic-wide dashboard statistics on the root page (`/`) with explicit tenant-prefixed keys.

**Where**: `app/controllers/appointments_controller.rb`

```ruby
def index
  @appointments = Appointment.all

  tenant = ApplicationRecord.current_tenant
  @clinic_stats = Rails.cache.fetch("#{tenant}/clinic_stats", expires_in: 15.minutes) do
    {
      total_patients: Patient.count,
      total_appointments: Appointment.count,
      total_staff: Staff.count,
      upcoming_appointments: Appointment.where("scheduled_at > ?", Time.current).count
    }
  end
end
```

**This is the ONE case where the gem doesn't help** — `Rails.cache` is a low-level primitive, not tied to model `cache_key`. You must manually prefix keys with the tenant name.

**Why this example is on the root page**: Every tenant visits the same route (`/`). Without the tenant prefix, the cache key `"clinic_stats"` is identical across tenants — Clinic A's cached counts would be served to Clinic B.

**How to test locally**:
1. Visit `http://development-clinic.localhost:3000/` (the root page)
2. First load — logs show 4 SQL COUNT queries
3. Reload within 15 minutes — no COUNT queries (cache hit)
4. Verify in console:
   ```ruby
   tenant = ApplicationRecord.current_tenant
   Rails.cache.read("#{tenant}/clinic_stats")
   # => {total_patients: 2, total_appointments: 2, total_staff: 1, upcoming_appointments: 0}

   # Wrong tenant key returns nil (isolated!)
   Rails.cache.read("other-clinic/clinic_stats")
   # => nil
   ```

**What happens WITHOUT the tenant prefix** (the danger):
```ruby
# BAD: Same key for all tenants!
Rails.cache.fetch("clinic_stats") { compute_stats }
# Clinic A visits / → caches {patients: 50}
# Clinic B visits / → reads {patients: 50} ← WRONG! That's Clinic A's data!
```

---

## Summary: What's Automatic vs Manual

| Caching Type | Tenant-Safe? | How? |
|---|---|---|
| Fragment caching (`<% cache record %>`) | Automatic | `cache_key` includes tenant |
| Collection caching (`cached: true`) | Automatic | Each record's `cache_key` includes tenant |
| Russian doll caching | Automatic | All nested keys include tenant |
| SQL query cache | Automatic | Isolated per connection pool (separate tenant DBs) |
| `Rails.cache` direct calls | **Manual** | You must prefix keys with `ApplicationRecord.current_tenant` |

---

## 5. Query Log Tags (`[tenant=X]` in SQL logs)

**What it does**: Appends the current tenant name to every SQL query in the logs, making it easy to see which tenant triggered each query.

**Where**: `config/environments/development.rb`

```ruby
config.active_record.query_log_tags_enabled = true
config.active_record.query_log_tags = [ :application, :controller, :action, :tenant ]
```

**How it looks in logs**:
```
User Load (0.3ms)  SELECT "users".* FROM "users" WHERE "users"."id" = ?
/*application='HealthcareManagement',controller='appointments',action='index',tenant='development-clinic'*/
```

Without the `:tenant` tag, you'd have no way to tell which tenant's database that query ran against.

---

## 6. Rails Console with `ARTENANT`

**What it does**: The gem automatically sets the tenant context in the Rails console using the `ARTENANT` environment variable.

**Usage**:
```bash
# Start console with a specific tenant
ARTENANT=development-clinic rails console

# Inside the console, the tenant is already set:
ApplicationRecord.current_tenant  # => "development-clinic"
Patient.count                     # queries development-clinic's database

# Switch tenant manually:
ApplicationRecord.with_tenant("metro-health-center") do
  Patient.count                   # queries metro-health-center's database
end
```

Without `ARTENANT`, the console uses the gem's `default_tenant` setting (configured in `config/initializers/active_record_tenanted.rb`).

---

## Gem Source Code References

| What | File in gem | Key code |
|---|---|---|
| `cache_key` override | `lib/active_record/tenanted/tenant.rb:15-17` | `"#{tenant}/#{super}"` |
| Job tenant serialization | `lib/active_record/tenanted/job.rb:19-21` | `super.merge!("tenant" => tenant)` |
| Job tenant execution | `lib/active_record/tenanted/job.rb:28-34` | `klass.with_tenant(tenant) { super }` |
| Global ID tenant param | `lib/active_record/tenanted/tenant.rb:25-27` | `super(options.merge(tenant: tenant))` |
| Global ID verification | `lib/active_record/tenanted/global_id.rb:19-31` | `WrongTenantError` on mismatch |
| Blob key prefix | `lib/active_record/tenanted/storage.rb:35-44` | `[tenant, token].join("/")` |
| Cable tenant resolution | `lib/active_record/tenanted/cable_connection.rb:15-17` | `identified_by :current_tenant` |
| Mailer URL interpolation | `lib/active_record/tenanted/mailer.rb:8-9` | `sprintf(host, tenant: current_tenant)` |
| Test job safety | `lib/active_record/tenanted/testing.rb:99-105` | `without_tenant { super }` |

---

## Running the Tests

```bash
# Run just the caching tests
rails test test/integration/caching_tenant_isolation_test.rb

# Run the full suite (should be 210 tests, 0 failures)
rails test && rails test:system
```
