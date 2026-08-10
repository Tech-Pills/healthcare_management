# ActiveRecord Tenanted Gem Guide

*Based on analysis of the activerecord-tenanted v0.3 gem by Basecamp*

## Overview

The `activerecord-tenanted` gem enables multi-tenancy in Rails applications by creating separate database connections and data isolation for each tenant. Currently supports SQLite only.

## Core Principles

1. **Data Isolation**: Each tenant gets its own separate database file
2. **Minimal Developer Intervention**: Should be "as easy as developing a single-tenant app"
3. **Safety First**: Prevents cross-tenant data access through strict connection management

## Key Components

### 1. Tenant Management

The gem provides several class-level methods for managing tenants:

```ruby
# Check current tenant context
ApplicationRecord.current_tenant

# Switch tenant context
ApplicationRecord.with_tenant("tenant-name") do
  # All database operations within this block use the specified tenant
  User.all # Returns users for this tenant only
end

# Create a new tenant database
ApplicationRecord.create_tenant("new-tenant")

# Destroy a tenant database
ApplicationRecord.destroy_tenant("old-tenant")

# List all existing tenants
ApplicationRecord.tenants
```

### 2. Model Configuration

#### Tenanted Models
Models that should be isolated per tenant:

```ruby
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  tenanted :primary  # Configure as tenanted using :primary database
end

class Patient < ApplicationRecord
  # Automatically tenanted through inheritance
  # Each tenant will have separate patient records
end
```

#### Global Models (Non-tenanted)
Models that should be accessible across all tenants:

```ruby
class GlobalRecord < ActiveRecord::Base
  self.abstract_class = true
  # Establish direct connection to bypass tenanting
  establish_connection :primary
end

class User < GlobalRecord
  # Global model - not tenant-specific
  # Same user records visible across all tenants
end
```

#### Subtenant Models
Models that belong to a tenant but delegate to a parent tenanted class:

```ruby
class Staff < ApplicationRecord
  # Already tenanted through ApplicationRecord inheritance
end

class StaffRole < ApplicationRecord
  subtenant_of Staff  # Delegates tenanting to Staff model
end
```

## Configuration Patterns

### Database Configuration

The gem expects database configurations that support tenanting. Example `database.yml`:

```yaml
development:
  primary: &primary
    adapter: sqlite3
    database: db/<%= Rails.env %>.sqlite3

  # Tenanted configurations are created dynamically
  # Each tenant gets: db/tenant-name.sqlite3
```

### Model Inheritance Hierarchy

```
ActiveRecord::Base
├── GlobalRecord (establish_connection :primary)
│   ├── User (global across tenants)
│   ├── Practice (global - manages tenants)
│   └── Session (global - belongs to users)
└── ApplicationRecord (tenanted :primary)
    ├── Patient (tenant-specific)
    ├── Staff (tenant-specific) 
    ├── Appointment (tenant-specific)
    └── SubtenantModel (subtenant_of ApplicationRecord)
```

## Error Handling

The gem provides specific exceptions:

```ruby
# Raised when accessing tenanted models without tenant context
ActiveRecord::Tenanted::NoTenantError

# Raised when accessing records from wrong tenant
ActiveRecord::Tenanted::WrongTenantError  

# Raised when referencing non-existent tenant
ActiveRecord::Tenanted::TenantDoesNotExistError

# Raised when tenant already exists during creation
ActiveRecord::Tenanted::TenantExistsError
```

## Common Usage Patterns

### 1. Tenant Creation with Setup

```ruby
class Practice < GlobalRecord
  after_create :setup_tenant
  
  private
  
  def setup_tenant
    tenant_name = "practice-#{id}"
    ApplicationRecord.create_tenant(tenant_name)
    
    # Seed tenant-specific data
    ApplicationRecord.with_tenant(tenant_name) do
      setup_initial_data
    end
  rescue ActiveRecord::Tenanted::TenantExistsError
    # Handle existing tenant gracefully
  end
end
```

### 2. Controller Tenant Switching

```ruby
class ApplicationController < ActionController::Base
  before_action :set_current_tenant
  
  private
  
  def set_current_tenant
    tenant_id = determine_tenant_from_request
    ApplicationRecord.current_tenant = tenant_id if tenant_id
  end
end
```

### 3. Seeding with Tenant Context

```ruby
# db/seeds.rb
practice = Practice.create!(name: "Test Clinic")

practice.with_tenant do
  Patient.create!(name: "John Doe")
  Staff.create!(name: "Dr. Smith")
end
```

### 4. Testing with Tenants

```ruby
class PatientTest < ActiveSupport::TestCase
  def setup
    @tenant = "test-tenant"
    ApplicationRecord.create_tenant(@tenant)
  end
  
  def teardown
    ApplicationRecord.destroy_tenant(@tenant)
  end
  
  def test_patient_isolation
    ApplicationRecord.with_tenant(@tenant) do
      patient = Patient.create!(name: "Test Patient")
      assert_equal 1, Patient.count
    end
    
    # Different tenant should have no patients
    ApplicationRecord.with_tenant("other-tenant") do
      assert_equal 0, Patient.count
    end
  end
end
```

## Best Practices

### 1. Model Organization
- Use `GlobalRecord` for models that need cross-tenant access (Users, Settings, etc.)
- Use `ApplicationRecord` (tenanted) for business data (Patients, Orders, etc.)
- Use `subtenant_of` sparingly for models that logically belong to a tenant but delegate connection handling

### 2. Tenant Lifecycle
- Always create tenants through a controlled process (e.g., Practice creation)
- Clean up tenant databases when no longer needed
- Handle `TenantExistsError` gracefully in case of race conditions

### 3. Development Workflow
- Set a default tenant in development console: `ApplicationRecord.current_tenant = "development-tenant"`
- Use meaningful tenant names for debugging
- Be explicit about tenant context in seeds and migrations

### 4. Error Handling
- Always rescue `NoTenantError` and redirect users appropriately
- Log tenant switching for audit trails
- Validate tenant access permissions before switching context

## Limitations & Considerations

1. **SQLite Only**: Currently only supports SQLite adapter
2. **Connection Overhead**: Each tenant requires its own connection pool
3. **Migration Complexity**: Migrations need to run against all tenant databases
4. **Global ID Support**: Built-in support for Rails Global ID but requires tenant context
5. **Testing Complexity**: Tests need careful tenant setup/teardown

## Migration Strategy

```ruby
# Custom rake task for tenant migrations
namespace :tenants do
  desc "Migrate all tenant databases"
  task migrate: :environment do
    ApplicationRecord.tenants.each do |tenant_name|
      puts "Migrating #{tenant_name}..."
      ApplicationRecord.with_tenant(tenant_name) do
        ActiveRecord::Tasks::DatabaseTasks.migrate
      end
    end
  end
end
```

## Console Usage

```ruby
# Set tenant context for console work
ApplicationRecord.current_tenant = "development-tenant"

# Check current tenant
ApplicationRecord.current_tenant

# List available tenants
ApplicationRecord.tenants

# Switch tenant context
ApplicationRecord.with_tenant("other-tenant") do
  # Work with other tenant's data
end
```

This guide is based on analysis of the activerecord-tenanted gem v0.3. The gem is still evolving, so refer to the official repository for the latest updates and features.