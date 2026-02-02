class CreateInstallationTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :installation_types do |t|
      t.string :system, null: false
      t.string :name, null: false
      t.string :code, null: false
      t.integer :position, default: 0
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :installation_types, [:system, :code], unique: true
    add_index :installation_types, [:system, :name], unique: true
    add_index :installation_types, [:system, :active]
  end
end
