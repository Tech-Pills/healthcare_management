class PatientsRecord < ActiveRecord::Base
  self.abstract_class = true

  tenanted :patients
end
