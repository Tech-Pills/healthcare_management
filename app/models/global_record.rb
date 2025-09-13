class GlobalRecord < ActiveRecord::Base
  self.abstract_class = true

  # Explicitly establish connection to global database
  connects_to database: { writing: :global, reading: :global }

  # This class provides a non-tenanted base for global models
  # like User, Practice, and Session that should be accessible
  # across all tenants without tenant context
end
