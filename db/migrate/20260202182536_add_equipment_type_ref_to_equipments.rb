class AddEquipmentTypeRefToEquipments < ActiveRecord::Migration[8.0]
  def change
    add_column :cute_equipments, :equipment_type_ref_id, :bigint
    add_column :fids_equipments, :equipment_type_ref_id, :bigint
    add_column :zamar_equipments, :equipment_type_ref_id, :bigint

    add_index :cute_equipments, :equipment_type_ref_id
    add_index :fids_equipments, :equipment_type_ref_id
    add_index :zamar_equipments, :equipment_type_ref_id

    add_foreign_key :cute_equipments, :equipment_types, column: :equipment_type_ref_id
    add_foreign_key :fids_equipments, :equipment_types, column: :equipment_type_ref_id
    add_foreign_key :zamar_equipments, :equipment_types, column: :equipment_type_ref_id
  end
end
