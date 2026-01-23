class ChangeEquipmentTypeToIntegerInCuteEquipments < ActiveRecord::Migration[8.0]
  def up
    # Сначала удаляем все данные, так как они некорректны
    execute "DELETE FROM cute_equipments"

    # Обнуляем колонку перед конвертацией
    execute "UPDATE cute_equipments SET equipment_type = NULL"

    # Меняем тип колонки на integer с USING
    execute "ALTER TABLE cute_equipments ALTER COLUMN equipment_type TYPE integer USING NULL"
  end

  def down
    change_column :cute_equipments, :equipment_type, :string
  end
end
