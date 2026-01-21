class CreateFidsInstallations < ActiveRecord::Migration[8.0]
  def change
    create_table :fids_installations do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :installation_type, null: false
      t.string :identifier

      t.timestamps
    end

    add_index :fids_installations, :name
    add_index :fids_installations, :installation_type
    add_index :fids_installations, [:user_id, :identifier], unique: true, where: "identifier IS NOT NULL"
  end
end
