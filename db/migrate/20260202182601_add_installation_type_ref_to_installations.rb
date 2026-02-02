class AddInstallationTypeRefToInstallations < ActiveRecord::Migration[8.0]
  def change
    add_column :cute_installations, :installation_type_ref_id, :bigint
    add_column :fids_installations, :installation_type_ref_id, :bigint
    add_column :zamar_installations, :installation_type_ref_id, :bigint

    add_index :cute_installations, :installation_type_ref_id
    add_index :fids_installations, :installation_type_ref_id
    add_index :zamar_installations, :installation_type_ref_id

    add_foreign_key :cute_installations, :installation_types, column: :installation_type_ref_id
    add_foreign_key :fids_installations, :installation_types, column: :installation_type_ref_id
    add_foreign_key :zamar_installations, :installation_types, column: :installation_type_ref_id
  end
end
