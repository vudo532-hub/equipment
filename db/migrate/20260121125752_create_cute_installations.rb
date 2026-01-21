class CreateCuteInstallations < ActiveRecord::Migration[8.0]
  def change
    create_table :cute_installations do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :installation_type, null: false
      t.string :identifier

      t.timestamps
    end

    add_index :cute_installations, :name
    add_index :cute_installations, :installation_type
    add_index :cute_installations, [:user_id, :identifier], unique: true, where: "identifier IS NOT NULL"
  end
end
