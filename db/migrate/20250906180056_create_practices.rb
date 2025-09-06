class CreatePractices < ActiveRecord::Migration[8.1]
  def change
    create_table :practices do |t|
      t.string :name
      t.string :address
      t.string :phone
      t.string :email
      t.string :license_number
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
