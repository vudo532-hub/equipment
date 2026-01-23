class ChangeUserIdToNullableForEquipmentAndInstallations < ActiveRecord::Migration[8.0]
  def change
    change_column_null :fids_equipments, :user_id, true
    change_column_null :fids_installations, :user_id, true
    change_column_null :cute_equipments, :user_id, true
    change_column_null :cute_installations, :user_id, true
  end
end
