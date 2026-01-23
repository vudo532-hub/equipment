# frozen_string_literal: true

class AddLastChangedByToEquipments < ActiveRecord::Migration[8.0]
  def change
    # Добавляем last_changed_by к CuteEquipments
    add_reference :cute_equipments, :last_changed_by, null: true, foreign_key: { to_table: :users }

    # Добавляем last_changed_by к FidsEquipments
    add_reference :fids_equipments, :last_changed_by, null: true, foreign_key: { to_table: :users }
  end
end
