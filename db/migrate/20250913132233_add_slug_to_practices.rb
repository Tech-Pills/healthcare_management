class AddSlugToPractices < ActiveRecord::Migration[8.1]
  def change
    add_column :practices, :slug, :string
    add_index :practices, :slug, unique: true
  end
end
