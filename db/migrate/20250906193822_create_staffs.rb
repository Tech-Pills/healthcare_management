class CreateStaffs < ActiveRecord::Migration[8.1]
  def change
    create_table :staffs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :practice, null: false, foreign_key: true
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :role, null: false
      t.string :license_number
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
