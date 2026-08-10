# activerecord-tenanted: Limitations & Future Features

Research for a conference talk about the `activerecord-tenanted` gem (v0.6.0). Compiled from the [GUIDE.md](https://github.com/basecamp/activerecord-tenanted/blob/main/GUIDE.md) roadmap, [open issues](https://github.com/basecamp/activerecord-tenanted/issues), and [discussions](https://github.com/basecamp/activerecord-tenanted/discussions).

---

## 1. Current Limitations

### 1.1 SQLite-Only (for now)

The gem currently only supports **SQLite** as the database adapter.

- **PostgreSQL**: Draft [PR #261](https://github.com/basecamp/activerecord-tenanted/pull/261) exists but no committed timeline. [Issue #282](https://github.com/basecamp/activerecord-tenanted/issues/282) has strong community demand.
- **MySQL**: [PR #204](https://github.com/basecamp/activerecord-tenanted/pull/204) (by @andrewmarkle) merged the first step of isolating SQLite-specific code, but MySQL support is not yet complete.
- [Discussion #194](https://github.com/basecamp/activerecord-tenanted/discussions/194) is the coordination thread for MySQL/PG contributors.

**Impact**: Major blocker for teams using PostgreSQL or MySQL in production.

### 1.2 Database Rake Tasks (Incomplete)

[Issue #222](https://github.com/basecamp/activerecord-tenanted/issues/222) tracks the "Database task roadmap (epic)".

Only bare minimum tasks are implemented: `db:migrate`, `db:drop`, linking to `db:prepare`.

**Missing critical tasks**:
- `db:migrate` with `VERSION` and `SCOPE`
- `db:migrate:up`, `db:migrate:down`, `db:rollback`
- `db:migrate:redo`
- `db:purge` ([Issue #153](https://github.com/basecamp/activerecord-tenanted/issues/153) — emits `NoTenantError` warnings, doesn't actually work)

Maintainer (@flavorjones) wants to "ruthlessly prioritize" migration-related tasks first. `db:rollback` has community upvotes as the most wanted.

### 1.3 Single Tenanted Connection Class

Only **one** connection class can be configured as `connection_class` for Rails integrations (Active Job, Active Storage, Action Cable, etc.).

[Discussion #183](https://github.com/basecamp/activerecord-tenanted/discussions/183) documents this: multiple tenanted base classes (e.g., `ApplicationRecord` + `PatientsRecord`) don't work for integrations.

**Impact**: Can't have separate tenanted databases for different compliance levels (e.g., HIPAA patient data in a separate DB).

#### Deep Dive: The Shard Swap Prohibition

The root cause is a **Rails safety mechanism** in `ActiveRecord::ConnectionHandling`. Here's what happens:

1. A request arrives at `development-clinic.localhost:3000`
2. The gem's `TenantSelector` middleware calls `ApplicationRecord.connected_to(shard: "development-clinic")`
3. Rails sets a **thread-local flag**: `shard_swapping_prohibited = true`
4. Your controller code runs inside this block

The prohibition is a safety feature — it prevents accidentally reading Tenant A's data while writing to Tenant B mid-request.

**The problem**: This flag is **global per thread**, not per connection class. Once `ApplicationRecord` is inside its `connected_to` block, no other connection class can swap shards either:

```
Request → TenantSelector sets ApplicationRecord shard (prohibition ON)
  → Controller queries PatientsRecord
    → PatientsRecord needs to swap to its own "development-clinic" shard
    → 💥 "cannot swap shard while shard swapping is prohibited"
```

This same mechanism causes the Solid gems issue below — Solid Cache tries to connect to its cache database while the shard swap prohibition is active.

**The upstream fix is already merged!** @flavorjones submitted [rails/rails#55927](https://github.com/rails/rails/pull/55927) ("Update shard swap prohibition to be more granular"), merged on October 30, 2025. It scopes the prohibition to the **connection specification name** instead of globally per thread. This means:

```
Request → TenantSelector swaps ApplicationRecord shard (prohibition ON for primary only)
  → Controller queries PatientsRecord
    → PatientsRecord swaps to its own shard (allowed! prohibition only applies to primary)
    → ✅ Works!
```

He also submitted [rails/rails#55933](https://github.com/rails/rails/pull/55933) introducing a specific `ShardSwapProhibitedError` exception (instead of generic `ArgumentError`), making it easier for libraries to catch and handle.

**Status**: Merged into Rails main — will ship in the next Rails release (8.2+). Until then, the workaround is to merge all tenanted models into a single `primary` database with one connection class, which is exactly what this project does.

### 1.4 Solid Gems Compatibility

[Discussion #234](https://github.com/basecamp/activerecord-tenanted/discussions/234) — Solid Cache, Solid Queue, and Solid Cable inside `with_tenant` blocks can trigger `cannot swap shard` errors.

- Solid Cache has a known upstream issue ([rails/solid_cache#219](https://github.com/rails/solid_cache/pull/219)) that conflicts with shard swap prohibition
- The upstream Rails fix ([rails/rails#55927](https://github.com/rails/rails/pull/55927)) for per-database shard swap prohibition is already merged and will resolve this in Rails 8.2+
- Solid Queue tenant iteration for periodic jobs is an open question ([Discussion #195](https://github.com/basecamp/activerecord-tenanted/discussions/195))

### 1.5 Third-Party Gem Compatibility

- **Devise**: [Issue #251](https://github.com/basecamp/activerecord-tenanted/issues/251) — `DeviseFailureApp` bypasses Rack middleware, losing tenant context on auth failures. Workaround: reorder middleware.
- **Ransack**: [Discussion #236](https://github.com/basecamp/activerecord-tenanted/discussions/236) — raises `NoTenantError` when searching. Ransack accesses `ActiveRecord::Base` connection directly.
- **General rule**: Any gem that uses `ActiveRecord::Base.connection` directly (instead of going through your tenanted model) will break.

### 1.6 Cross-Database Associations

[Issue #201](https://github.com/basecamp/activerecord-tenanted/issues/201) — "Easy associations between tenanted and untenanted models" is a planned feature, not yet implemented.

Currently requires manual workarounds:
- `optional: true` on `belongs_to`
- Custom `validates :foreign_key, presence: true`
- `disable_joins: true` for `has_one/many :through` across databases
- Avoid `joins()` and nested `where()` across databases

Fixtures for cross-database associations need special handling (`tenant_id` column auto-write).

### 1.7 Connection Pool Management

- Default cap of **50 connection pools**; LRU eviction when exceeded
- Trade-off: too low = latency from reconnections; too high = file descriptor/memory pressure
- Destroy tenant race condition: existing connections/statements/transactions may not be properly closed (GUIDE.md TODO)

### 1.8 Rails Edge Compatibility

[Issue #279](https://github.com/basecamp/activerecord-tenanted/issues/279) — `type_for_column` API changed in Rails main ([rails/rails#54348](https://github.com/rails/rails/pull/54348)), breaking the gem's patches. The gem tracks Rails edge, so breaking changes can appear between Rails releases.

---

## 2. Production Readiness

### From the maintainer ([Discussion #250](https://github.com/basecamp/activerecord-tenanted/discussions/250)):

> "Unless you're willing and able to contribute to the codebase, I would not recommend using it in mission-critical applications yet. That said, I've been running it for an internal application (on SQLite) for a few months and it's been rock solid."

### Fizzy removal ([Discussion #260](https://github.com/basecamp/activerecord-tenanted/discussions/260)):

- The gem was removed from Basecamp's Fizzy app — **NOT** because of stability issues
- @flavorjones: "activerecord-tenanted was working very well in Fizzy, and I consider it stable enough to run in production"
- Removed because Fizzy had additional requirements (SQLite replication to hot read replicas with automatic geo-failover) that warranted a different approach

### Stress test results ([Discussion #203](https://github.com/basecamp/activerecord-tenanted/discussions/203)):

- Community member (@lairtonmendes) tested with **1,000 tenants**, each with **100,000 rows**
- @flavorjones benchmarked ~400-800 write requests/sec depending on hardware
- SQLite performed well under concurrent multi-tenant load

---

## 3. Future Features / Planned Work

### 3.1 From GUIDE.md TODO Checklists

| Feature | Status | Notes |
|---|---|---|
| PostgreSQL/MySQL support | In progress | PR #261 (PG draft), PR #204 (MySQL step 1 merged) |
| Full database rake tasks | Partially done | Issue #222 epic |
| Bucketed database paths | TODO | For scaling to many tenants on disk |
| Implicit migration opt-in | TODO | Currently auto-migrates on pool creation |
| Installation generator | TODO | Auto-generate database.yml + initializer |
| ActionMailbox integration | TODO | Needs a use case for mail routing |
| Metrics/instrumentation | TODO | Create/migrate/destroy tenant events + pool lifecycle |
| Action Cable disconnection | TODO | `remote_connections.where(current_tenant: ...)` |
| Action Cable logger tags | TODO | Add tenant to cable logger tags |
| Shard-specific swap prohibition | **Merged in Rails** | [rails/rails#55927](https://github.com/rails/rails/pull/55927) — ships in Rails 8.2+ |
| Cross-database association helpers | TODO | Issue #201 |
| Race condition handling for destroy | TODO | Close existing connections properly |

### 3.2 From Discussions

| Topic | Discussion | Summary |
|---|---|---|
| Geo-aware lazy migrations | [#213](https://github.com/basecamp/activerecord-tenanted/discussions/213) | @rubys proposed lazy migrations for multi-region deployments |
| Exclude default tenant from iteration | [#208](https://github.com/basecamp/activerecord-tenanted/discussions/208) | `with_each_tenant(exclude_default: true)` — config workaround exists |
| Background job tenant iteration | [#195](https://github.com/basecamp/activerecord-tenanted/discussions/195) | Patterns for `with_each_tenant` in jobs; `ARTENANT` env var for rake tasks |
| Shared database in tests | [#276](https://github.com/basecamp/activerecord-tenanted/discussions/276) | Workaround: connect shared record to default test tenant |

---

## 4. Key Takeaways for the Talk

### What the gem handles automatically (and well):

1. **Fragment caching** — `cache_key` override includes tenant prefix
2. **Collection & Russian doll caching** — all nested keys include tenant
3. **Active Storage** — blob key prefixing (`tenant/token`)
4. **Global ID** — tenant parameter included (Action Cable, Active Job, Turbo)
5. **Active Job** — tenant serialization/deserialization in job payloads
6. **Action Cable** — stream isolation via tenant-scoped Global IDs
7. **ActionMailer** — URL interpolation with `%{tenant}` in host
8. **Test framework** — default tenant, parallel tests, `without_tenant` helper
9. **SQL query cache** — isolated per connection pool (separate tenant DBs)
10. **Console** — tenant context via `ARTENANT` env var

### What requires manual work:

1. **`Rails.cache` direct calls** — must prefix keys with tenant name
2. **Cross-database associations** — `optional: true`, `disable_joins: true`, custom validations
3. **Third-party gems** — any gem that accesses `ActiveRecord::Base.connection` directly needs workarounds

### Honest limitations to mention:

1. SQLite-only (PG/MySQL in progress but no committed timeline)
2. Incomplete rake tasks (no `db:rollback`, `db:migrate:up/down`, etc.)
3. Single tenanted connection class (can't have multiple isolated DBs per tenant)
4. Devise/Ransack and other popular gems may need workarounds
5. "Not recommended for mission-critical apps unless you can contribute" — maintainer
6. Still pre-1.0 — API may change

### Strengths to highlight:

1. **Rails conventions** — "developing multi-tenant should be as easy as single-tenant"
2. **Built on Rails 6.1+ horizontal sharding** — thread-safe, not the old Apartment reconnection hack
3. **Proven stable** in production (Basecamp internal app, community stress tests with 1,000 tenants)
4. **Comprehensive integration** — 10+ Rails subsystems covered automatically
5. **Active community** and responsive maintainer
6. Fizzy removal was for **strategic reasons** (geo-replication needs), NOT stability concerns

---

## Source References

| Source | URL |
|---|---|
| GUIDE.md (roadmap + TODOs) | https://github.com/basecamp/activerecord-tenanted/blob/main/GUIDE.md |
| Open Issues | https://github.com/basecamp/activerecord-tenanted/issues |
| Discussions | https://github.com/basecamp/activerecord-tenanted/discussions |
| Database task epic | https://github.com/basecamp/activerecord-tenanted/issues/222 |
| PostgreSQL support | https://github.com/basecamp/activerecord-tenanted/issues/282 |
| MySQL/PG coordination | https://github.com/basecamp/activerecord-tenanted/discussions/194 |
| Production readiness | https://github.com/basecamp/activerecord-tenanted/discussions/250 |
| Fizzy removal context | https://github.com/basecamp/activerecord-tenanted/discussions/260 |
| Stress test results | https://github.com/basecamp/activerecord-tenanted/discussions/203 |
| Cross-database associations | https://github.com/basecamp/activerecord-tenanted/issues/201 |
| Multi-database limitations | https://github.com/basecamp/activerecord-tenanted/discussions/183 |
| Solid gems compatibility | https://github.com/basecamp/activerecord-tenanted/discussions/234 |
