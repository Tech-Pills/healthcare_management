class RemoveForeignKeysFromStaffs < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :staffs, :practices if foreign_key_exists?(:staffs, :practices)
  end
end
