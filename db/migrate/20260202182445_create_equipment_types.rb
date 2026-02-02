class CreateEquipmentTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :equipment_types do |t|
      t.string :system, null: false
      t.string :name, null: false
      t.string :code, null: false
      t.integer :position, default: 0
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :equipment_types, [:system, :code], unique: true
    add_index :equipment_types, [:system, :name], unique: true
    add_index :equipment_types, [:system, :active]
  end
end
