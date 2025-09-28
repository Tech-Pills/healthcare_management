class CreateMedicalRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :medical_records do |t|
      t.references :patient, null: false, foreign_key: true
      t.references :appointment, null: false, foreign_key: true
      t.datetime :recorded_at, null: false
      t.decimal :weight, precision: 5, scale: 2
      t.decimal :height, precision: 5, scale: 2
      t.integer :heart_rate
      t.decimal :temperature, precision: 4, scale: 2
      t.integer :blood_pressure_systolic
      t.integer :blood_pressure_diastolic
      t.text :diagnosis
      t.text :medications
      t.text :allergies
      t.text :notes

      t.timestamps
    end
  end
end
