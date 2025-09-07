class CreatePatients < ActiveRecord::Migration[8.1]
  def change
    create_table :patients do |t|
      t.references :practice, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.date :date_of_birth, null: false
      t.string :gender
      t.string :phone, null: false
      t.string :email
      t.text :address
      t.text :emergency_contact_name
      t.text :emergency_contact_phone
      t.string :insurance_provider
      t.string :insurance_policy_number
      t.boolean :active, default: true
      t.string :blood_type

      t.timestamps
    end
  end
end
