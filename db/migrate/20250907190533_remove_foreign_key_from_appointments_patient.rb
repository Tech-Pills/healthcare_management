class RemoveForeignKeyFromAppointmentsPatient < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :appointments, :patients
  end
end
