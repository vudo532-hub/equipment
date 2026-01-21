class CreateFidsEquipments < ActiveRecord::Migration[8.0]
  def change
    create_table :fids_equipments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :fids_installation, null: true, foreign_key: true
      t.string :equipment_type, null: false
      t.string :equipment_model
      t.string :inventory_number, null: false
      t.string :serial_number
      t.integer :status, default: 0, null: false
      t.text :note
      t.datetime :last_action_date

      t.timestamps
    end

    add_index :fids_equipments, :equipment_type
    add_index :fids_equipments, :inventory_number
    add_index :fids_equipments, :serial_number
    add_index :fids_equipments, :status
    add_index :fids_equipments, :last_action_date
    add_index :fids_equipments, [:user_id, :inventory_number], unique: true
  end
end
