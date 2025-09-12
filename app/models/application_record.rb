class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
  tenanted

  connects_to database: { writing: :primary, reading: :primary }
end
