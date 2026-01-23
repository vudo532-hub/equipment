# frozen_string_literal: true

class CreateZamarInstallations < ActiveRecord::Migration[8.0]
  def change
    create_table :zamar_installations do |t|
      t.references :user, null: true, foreign_key: true
      t.string :name, null: false
      t.string :installation_type, null: false
      t.string :identifier
      t.integer :terminal, default: nil

      t.timestamps
    end

    add_index :zamar_installations, :name
    add_index :zamar_installations, :installation_type
    add_index :zamar_installations, :terminal
    add_index :zamar_installations, [:user_id, :identifier], unique: true, where: "identifier IS NOT NULL"
  end
end
