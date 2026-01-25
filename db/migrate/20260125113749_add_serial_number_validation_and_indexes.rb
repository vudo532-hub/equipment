class AddSerialNumberValidationAndIndexes < ActiveRecord::Migration[8.0]
  def change
    # Индексы для CUTE Equipment
    add_index :cute_equipments, :status, if_not_exists: true
    add_index :cute_equipments, :serial_number, if_not_exists: true
    add_index :cute_equipments, [:equipment_type, :cute_installation_id], if_not_exists: true
    add_index :cute_equipments, :equipment_model, if_not_exists: true

    # Индексы для FIDS Equipment
    add_index :fids_equipments, :status, if_not_exists: true
    add_index :fids_equipments, :serial_number, if_not_exists: true
    add_index :fids_equipments, [:equipment_type, :fids_installation_id], if_not_exists: true
    add_index :fids_equipments, :equipment_model, if_not_exists: true

    # Индексы для Zamar Equipment
    add_index :zamar_equipments, :status, if_not_exists: true
    add_index :zamar_equipments, :serial_number, if_not_exists: true
    add_index :zamar_equipments, [:equipment_type, :zamar_installation_id], if_not_exists: true
    add_index :zamar_equipments, :equipment_model, if_not_exists: true

    # Индексы для Installations (терминалы)
    add_index :cute_installations, :terminal, if_not_exists: true
    add_index :fids_installations, :terminal, if_not_exists: true
    add_index :zamar_installations, :terminal, if_not_exists: true
  end
end
