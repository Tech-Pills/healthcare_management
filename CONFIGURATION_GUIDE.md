# ActiveRecord::Tenanted - Complete Configuration Guide

This guide covers the key configuration aspects for using `activerecord-tenanted` in your Rails application, including ActionMailer, Active Storage, migrations, and Action Cable.

## Table of Contents

- [ActionMailer Configuration](#actionmailer-configuration)
- [Active Storage Configuration](#active-storage-configuration)
- [Migrations Paths (Tenanted vs Global Databases)](#migrations-paths-tenanted-vs-global-databases)
- [Action Cable Configuration](#action-cable-configuration)

---

## ActionMailer Configuration

### Overview

The gem automatically interpolates the current tenant name into your ActionMailer URL configuration. This is essential for multi-tenant apps where each tenant has their own subdomain.

### How It Works

When you configure ActionMailer with a `%{tenant}` format specifier in the host, the gem automatically replaces it with the current tenant name when generating URLs in emails.

**Implementation**: [lib/active_record/tenanted/mailer.rb:6-12](lib/active_record/tenanted/mailer.rb#L6-L12)

```ruby
def url_options(...)
  super.tap do |options|
    if ActiveRecord::Tenanted.connection_class && options.key?(:host)
      options[:host] = sprintf(options[:host], tenant: ActiveRecord::Tenanted.connection_class.current_tenant)
    end
  end
end
```

### Configuration

Create or update an initializer `config/initializers/tenanting.rb`:

```ruby
Rails.application.configure do
  # For subdomain-based tenanting
  config.action_mailer.default_url_options = { host: "%{tenant}.example.com" }

  # Or with a port for development
  config.action_mailer.default_url_options = { host: "%{tenant}.example.com", port: 3000 }
end
```

Or configure per environment in `config/environments/production.rb`:

```ruby
Rails.application.configure do
  config.action_mailer.default_url_options = {
    host: "%{tenant}.yourapp.com",
    protocol: "https"
  }
end
```

### Usage Example

In your mailer view `app/views/user_mailer/welcome.html.erb`:

```erb
<p>
  <%= link_to "Visit your dashboard", dashboard_url %>
</p>
```

**Result:**
- For tenant "acme": `http://acme.example.com/dashboard`
- For tenant "widgets": `http://widgets.example.com/dashboard`

The `%{tenant}` placeholder is automatically replaced without any additional code in your mailers!

---

## Active Storage Configuration

### Overview

The gem provides automatic file isolation for Active Storage by:

1. **Prefixing blob keys with the tenant name** (e.g., `acme/abc123def456`)
2. **Organizing files into tenant-specific directories**

This ensures complete file isolation between tenants.

### How It Works

#### 1. Blob Keys Include Tenant

**Implementation**: [lib/active_record/tenanted/storage.rb:30-42](lib/active_record/tenanted/storage.rb#L30-L42)

```ruby
def key
  self[:key] ||= if klass = ActiveRecord::Tenanted.connection_class
    unless tenant = klass.current_tenant
      raise NoTenantError, "Cannot generate a Blob key without a tenant"
    end

    token = self.class.generate_unique_secure_token(...)
    [ tenant, token ].join("/")  # e.g., "acme/abc123def456"
  end
end
```

#### 2. Disk Storage Path Includes Tenant

**Implementation**: [lib/active_record/tenanted/storage.rb:19-26](lib/active_record/tenanted/storage.rb#L19-L26)

```ruby
def path_for(key)
  if ActiveRecord::Tenanted.connection_class && key.include?("/")
    tenant, key = key.split("/", 2)
    File.join(root, tenant, folder_for(key), key)
  end
end
```

Creates paths like: `storage/acme/ab/cd/abcd123...`

### Configuration Options

#### Option 1: Simple Configuration (Standard Root)

In `config/storage.yml`:

```yaml
local:
  service: Disk
  root: <%= Rails.root.join("storage") %>

production:
  service: Disk
  root: <%= Rails.root.join("storage") %>
```

Files stored at: `storage/tenant-name/ab/cd/abcd123...`

#### Option 2: Tenant-Specific Root (Recommended)

In `config/storage.yml`:

```yaml
local:
  service: Disk
  root: <%= Rails.root.join("storage/%{tenant}") %>

test:
  service: Disk
  root: <%= Rails.root.join("tmp/storage/%{tenant}") %>

production:
  service: Disk
  root: <%= Rails.root.join("storage/%{tenant}") %>
```

Files stored at: `storage/tenant-name/ab/cd/abcd123...`

The `%{tenant}` placeholder in the root path is interpolated automatically.

### Set Active Storage Service

In your environment configs (e.g., `config/environments/production.rb`):

```ruby
Rails.application.configure do
  config.active_storage.service = :local
end
```

### Usage

No changes needed in your models or controllers! Use Active Storage normally:

```ruby
class User < ApplicationRecord
  has_one_attached :avatar
end

# In your controller
def update
  @user.avatar.attach(params[:avatar])
  # File automatically stored in current tenant's directory
end
```

### File Structure Examples

**Option 1 (Simple):**
```
storage/
  acme/
    ab/
      cd/
        acme/abcd1234efgh5678
```

**Option 2 (Tenant-Specific Root - Recommended):**
```
storage/
  acme/
    ab/
      cd/
        abcd1234efgh5678
```

### Important Notes

- **Automatic Setup**: Gem prepends modules to `ActiveStorage::Blob` and `ActiveStorage::Service::DiskService`
- **No Manual Code**: All file uploads are automatically tenant-aware
- **Safety**: Uploading without tenant context raises `NoTenantError`
- **Database Tables**: `ActiveStorage::Record` tables stored in each tenant's database (if `tenanted_rails_records` enabled)

---

## Migrations Paths (Tenanted vs Global Databases)

### Overview

You can configure **separate migration directories** for your tenanted database and your global/shared database using the `migrations_paths` option in `database.yml`.

### Configuration

#### 1. Configure `config/database.yml`

```yaml
development:
  # Tenanted database (one per tenant)
  primary:
    tenanted: true
    adapter: sqlite3
    database: storage/tenants/%{tenant}/main.sqlite3
    migrations_paths: db/migrate  # Tenant-specific migrations

  # Global/shared database (single database for all tenants)
  shared:
    adapter: sqlite3
    database: storage/shared.sqlite3
    migrations_paths: db/shared_migrate  # Shared migrations

production:
  primary:
    tenanted: true
    adapter: sqlite3
    database: storage/production/%{tenant}/main.sqlite3
    migrations_paths: db/migrate

  shared:
    adapter: sqlite3
    database: storage/production_shared.sqlite3
    migrations_paths: db/shared_migrate
```

#### 2. Create Model Base Classes

**Tenanted models** in `app/models/application_record.rb`:

```ruby
# Tenanted models (users, posts, etc.)
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
  tenanted  # Connects to 'primary' tenanted database
end
```

**Shared/global models** in `app/models/shared_record.rb`:

```ruby
# Shared/global models (announcements, system settings, etc.)
class SharedRecord < ActiveRecord::Base
  self.abstract_class = true
  connects_to database: { writing: :shared }
end
```

#### 3. Create Your Models

**Tenanted models** (data isolated per tenant):

```ruby
class User < ApplicationRecord
  # Uses db/migrate migrations
  # Stored in each tenant's database
end

class Post < ApplicationRecord
  # Uses db/migrate migrations
  # Stored in each tenant's database
end
```

**Shared/global models** (data shared across all tenants):

```ruby
class Announcement < SharedRecord
  # Uses db/shared_migrate migrations
  # Stored in shared database
end

class SystemSetting < SharedRecord
  # Uses db/shared_migrate migrations
  # Stored in shared database
end
```

### Directory Structure

```
db/
├── migrate/                          # Tenanted migrations
│   ├── 20250101000000_create_users.rb
│   ├── 20250101000001_create_posts.rb
│   └── 20250101000002_add_published_to_posts.rb
│
└── shared_migrate/                   # Shared/global migrations
    ├── 20250101000000_create_announcements.rb
    └── 20250101000001_create_system_settings.rb
```

### Running Migrations

#### For Tenanted Database

```bash
# Migrate all existing tenants
rails db:migrate

# Migrate specific tenant
ARTENANT=acme rails db:migrate

# Create new tenant (automatically runs migrations)
ApplicationRecord.create_tenant("acme")
```

#### For Shared Database

```bash
# Migrate the shared database
rails db:migrate:shared
```

### Creating Migrations

**Tenanted Migration:**

```bash
rails generate migration CreateUsers email:string
# Creates: db/migrate/20250101000000_create_users.rb
```

**Shared Migration:**

```bash
rails generate migration CreateAnnouncements message:string --database=shared
# Creates: db/shared_migrate/20250101000000_create_announcements.rb
```

### Usage Example

```ruby
# Tenanted data - requires tenant context
ApplicationRecord.with_tenant("acme") do
  user = User.create(email: "user@acme.com")
  post = Post.create(title: "Hello", body: "World", user: user)
end

# Shared data - works globally, no tenant context needed
announcement = Announcement.create(message: "System maintenance tonight")
setting = SystemSetting.create(key: "max_upload_size", value: "100MB")

# Shared data is visible to all tenants
ApplicationRecord.with_tenant("acme") do
  Announcement.all  # Returns all announcements (shared across tenants)
end

ApplicationRecord.with_tenant("widgets") do
  Announcement.all  # Same announcements (shared data)
end
```

### Key Points

- **Separate Migration Paths**: Use `migrations_paths` for different directories
- **Tenanted Database**: One database per tenant, stores tenant-specific data
- **Shared Database**: Single database for all tenants, stores global data
- **Automatic Migration**: New tenant creation automatically runs migrations
- **No Tenant Context for Shared**: Shared models work globally without tenant context

---

## Action Cable Configuration

### Overview

The gem automatically makes Action Cable tenant-aware so that:

1. **WebSocket connections are authenticated per tenant**
2. **All channel actions run within tenant context**
3. **Broadcasts are isolated** - Turbo streams don't leak between tenants
4. **Global IDs include tenant** - Records are verified to belong to correct tenant

### How It Works

The gem extends Action Cable's connection handling:

**Implementation**: [lib/active_record/tenanted/cable_connection.rb:6-50](lib/active_record/tenanted/cable_connection.rb#L6-L50)

1. **Identifies connection by tenant**: `identified_by :current_tenant`
2. **Resolves tenant from request**: Uses subdomain (or custom resolver)
3. **Wraps commands in tenant context**: `around_command :with_tenant`
4. **Rejects invalid tenants**: Returns unauthorized for non-existent tenants

### Configuration

#### 1. Basic Setup (No Code Needed!)

If using default subdomain-based tenant resolution, **no configuration is needed**:

`app/channels/application_cable/connection.rb`:

```ruby
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    # That's it! Gem automatically handles tenant resolution
  end
end
```

#### 2. Custom Connection Logic

If you need authentication or custom logic, **you must call `super`**:

```ruby
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      super  # ⚠️ IMPORTANT: Call super to set up tenant context

      # Your custom logic here
      self.current_user = find_verified_user
    end

    private
      def find_verified_user
        # Runs within tenant context automatically
        if verified_user = User.find_by(id: cookies.encrypted[:user_id])
          verified_user
        else
          reject_unauthorized_connection
        end
      end
  end
end
```

#### 3. Custom Tenant Resolver (Optional)

Configure custom tenant resolution in `config/initializers/tenanting.rb`:

```ruby
Rails.application.configure do
  # Custom tenant resolution for Action Cable
  config.active_record_tenanted.tenant_resolver = ->(request) do
    # Extract tenant from path, custom header, etc.
    request.params[:tenant] || request.subdomain
  end
end
```

### How Channels Work

Channels automatically run within tenant context:

`app/channels/chat_channel.rb`:

```ruby
class ChatChannel < ApplicationCable::Channel
  def subscribed
    # Automatically runs within current_tenant context
    stream_from "chat_#{current_room_id}"
  end

  def receive(data)
    # Automatically runs within current_tenant context
    message = Message.create!(body: data["message"], room_id: current_room_id)
  end

  private
    def current_room_id
      params[:room_id]
    end
end
```

### Turbo Streams (Automatic Tenant Isolation)

Turbo broadcasts are automatically tenant-aware:

`app/models/post.rb`:

```ruby
class Post < ApplicationRecord
  # Automatically broadcasts within tenant context
  broadcasts_to ->(post) { :posts }

  # Or explicitly:
  after_update_commit :broadcast_update

  private
    def broadcast_update
      broadcast_replace_to self
    end
end
```

In your view:

```erb
<%= turbo_stream_from @post %>

<%= turbo_frame_tag @post do %>
  <%= render @post %>
<% end %>
```

**How it ensures isolation:**

1. The `@post` global ID includes tenant: `gid://app/Post/1?tenant=acme`
2. Turbo generates tenant-specific stream: `acme:post:1`
3. Different tenants with same record ID get different streams:
   - Tenant "acme": `gid://app/Post/1?tenant=acme` → `acme:post:1`
   - Tenant "widgets": `gid://app/Post/1?tenant=widgets` → `widgets:post:1`

### Global IDs Include Tenant

**Implementation**: [lib/active_record/tenanted/tenant.rb:25-30](lib/active_record/tenanted/tenant.rb#L25-L30)

Every tenanted record's Global ID includes the tenant parameter:

```ruby
ApplicationRecord.with_tenant("acme") do
  user = User.find(1)
  user.to_global_id
  # => gid://myapp/User/1?tenant=acme
end
```

When the Global ID is used (in Action Cable, Active Job, etc.), it's verified to match the current tenant.

### Complete Example: Chat Application

`app/channels/room_channel.rb`:

```ruby
class RoomChannel < ApplicationCable::Channel
  def subscribed
    # Runs within tenant context automatically
    room = Room.find(params[:id])
    stream_for room  # Stream is tenant-specific
  end

  def speak(data)
    # Runs within tenant context automatically
    room = Room.find(params[:id])
    message = room.messages.create!(
      user: current_user,
      body: data["message"]
    )

    # Broadcast to tenant-specific stream
    RoomChannel.broadcast_to(room, message: render_message(message))
  end

  private
    def render_message(message)
      ApplicationController.render(
        partial: "messages/message",
        locals: { message: message }
      )
    end
end
```

JavaScript client:

```javascript
// Connects to tenant-specific WebSocket
// e.g., wss://acme.myapp.com/cable for tenant "acme"
consumer.subscriptions.create(
  { channel: "RoomChannel", id: roomId },
  {
    received(data) {
      // Receives only messages for current tenant
      console.log(data.message)
    },

    speak(message) {
      this.perform('speak', { message: message })
    }
  }
)
```

### Testing Action Cable

**Channel tests:**

```ruby
class RoomChannelTest < ActionCable::Channel::TestCase
  test "subscribes to room" do
    # Test automatically runs within tenant context
    room = rooms(:one)

    subscribe(id: room.id)

    assert subscription.confirmed?
  end

  test "broadcasting to room" do
    room = rooms(:one)
    subscribe(id: room.id)

    perform :speak, message: "Hello!"

    assert_broadcast_on(
      RoomChannel.broadcasting_for(room),
      message: /Hello!/
    )
  end
end
```

**Connection tests:**

```ruby
class ApplicationCable::ConnectionTest < ActionCable::Connection::TestCase
  test "connects with valid tenant" do
    connect

    # Tenant automatically set from test fixtures
    assert_equal ApplicationRecord.current_tenant, connection.current_tenant
  end
end
```

### Key Points

- **Zero Configuration**: Works automatically with subdomain-based tenanting
- **Call `super`**: If you override `#connect`, always call `super` first
- **Automatic Context**: All channel actions run within tenant context
- **Isolated Broadcasts**: Turbo streams and broadcasts are tenant-specific
- **Global ID Safety**: Records verified to belong to current tenant
- **Testing**: Tests automatically run within tenant context

No special code needed in your channels - the gem handles all tenant isolation automatically!

---

## Additional Resources

- **Main Documentation**: [GUIDE.md](GUIDE.md)
- **Project Overview**: [CLAUDE.md](CLAUDE.md)
- **Source Code**: [lib/active_record/tenanted/](lib/active_record/tenanted/)
- **Test Examples**: [test/integration/](test/integration/)

## Summary

The `activerecord-tenanted` gem provides comprehensive Rails integration with minimal configuration:

- **ActionMailer**: Add `%{tenant}` to host configuration
- **Active Storage**: Add `%{tenant}` to storage root (optional)
- **Migrations**: Use `migrations_paths` for separate migration directories
- **Action Cable**: Works automatically, just call `super` in custom `#connect` methods

All tenant isolation is handled automatically by the gem!
