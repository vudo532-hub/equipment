class CreateRepairBatches < ActiveRecord::Migration[8.0]
  def change
    create_table :repair_batches do |t|
      t.string :repair_number, null: false
      t.references :user, foreign_key: true
      t.integer :equipment_count, default: 0
      t.string :status, default: "sent"
      t.text :notes
      t.timestamps
    end

    add_index :repair_batches, :repair_number, unique: true
    add_index :repair_batches, :status
    add_index :repair_batches, :created_at
  end
end
