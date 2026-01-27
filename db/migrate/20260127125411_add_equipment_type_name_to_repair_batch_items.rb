class AddEquipmentTypeNameToRepairBatchItems < ActiveRecord::Migration[8.0]
  def change
    add_column :repair_batch_items, :equipment_type_name, :string
  end
end
