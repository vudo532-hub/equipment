class CreateCuteEquipments < ActiveRecord::Migration[8.0]
  def change
    create_table :cute_equipments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :cute_installation, null: true, foreign_key: true
      t.string :equipment_type, null: false
      t.string :equipment_model
      t.string :inventory_number, null: false
      t.string :serial_number
      t.integer :status, default: 0, null: false
      t.text :note
      t.datetime :last_action_date

      t.timestamps
    end

    add_index :cute_equipments, :equipment_type
    add_index :cute_equipments, :inventory_number
    add_index :cute_equipments, :serial_number
    add_index :cute_equipments, :status
    add_index :cute_equipments, :last_action_date
    add_index :cute_equipments, [:user_id, :inventory_number], unique: true
  end
end
