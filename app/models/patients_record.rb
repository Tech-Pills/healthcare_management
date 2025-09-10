class PatientsRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :patients, reading: :patients_replica }
end
