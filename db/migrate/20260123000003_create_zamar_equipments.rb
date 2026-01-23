# frozen_string_literal: true

class CreateZamarEquipments < ActiveRecord::Migration[8.0]
  def change
    create_table :zamar_equipments do |t|
      t.references :user, null: true, foreign_key: true
      t.references :zamar_installation, null: true, foreign_key: true
      t.references :last_changed_by, null: true, foreign_key: { to_table: :users }
      t.integer :equipment_type, null: false, default: 0
      t.string :equipment_model
      t.string :inventory_number, null: false
      t.string :serial_number
      t.integer :status, default: 0, null: false
      t.text :note
      t.datetime :last_action_date

      t.timestamps
    end

    add_index :zamar_equipments, :equipment_type
    add_index :zamar_equipments, :inventory_number
    add_index :zamar_equipments, :serial_number
    add_index :zamar_equipments, :status
    add_index :zamar_equipments, :last_action_date
    add_index :zamar_equipments, [:user_id, :inventory_number], unique: true
  end
end
