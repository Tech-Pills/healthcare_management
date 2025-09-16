Rails.application.configure do
  # Cada modelo herdado de ApplicationRecord é Tenanted
  config.active_record_tenanted.connection_class = "ApplicationRecord"
  # Subdomínio da request é usado para resolver o Tenant
  config.active_record_tenanted.tenant_resolver = ->(request) { request.subdomain }
end
