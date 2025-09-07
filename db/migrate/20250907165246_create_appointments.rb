class CreateAppointments < ActiveRecord::Migration[8.1]
  def change
    create_table :appointments do |t|
      t.references :practice, null: false, foreign_key: true
      t.references :patient, null: false, foreign_key: true
      t.references :provider, null: false, foreign_key: { to_table: :staffs }
      t.datetime :scheduled_at, null: false
      t.integer :duration_minutes, default: 30
      t.string :status, default: "scheduled"
      t.text :notes

      t.timestamps
    end
  end
end
