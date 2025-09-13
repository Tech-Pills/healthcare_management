class RemoveForeignKeysFromTenantedModels < ActiveRecord::Migration[8.1]
  def change
    # Remove cross-database foreign keys for tenanted models
    remove_foreign_key :sessions, :users if foreign_key_exists?(:sessions, :users)
    remove_foreign_key :patients, :practices if foreign_key_exists?(:patients, :practices)
    remove_foreign_key :appointments, :patients if foreign_key_exists?(:appointments, :patients)
    remove_foreign_key :appointments, :practices if foreign_key_exists?(:appointments, :practices)
  end
end
