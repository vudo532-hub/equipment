class CreateRepairBatchItems < ActiveRecord::Migration[8.0]
  def change
    create_table :repair_batch_items do |t|
      t.references :repair_batch, null: false, foreign_key: true
      t.string :equipment_type, null: false  # CuteEquipment, FidsEquipment, ZamarEquipment
      t.bigint :equipment_id, null: false
      t.string :system, null: false  # CUTE, FIDS, Zamar
      t.string :serial_number
      t.string :model
      t.string :inventory_number
      t.string :terminal
      t.string :installation_name
      t.text :note
      t.datetime :created_at
    end

    add_index :repair_batch_items, [:equipment_type, :equipment_id]
    add_index :repair_batch_items, :serial_number
    add_index :repair_batch_items, :system
  end
end
