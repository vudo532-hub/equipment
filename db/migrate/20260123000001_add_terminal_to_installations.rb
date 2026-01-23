# frozen_string_literal: true

class AddTerminalToInstallations < ActiveRecord::Migration[8.0]
  def change
    # Добавляем поле terminal к CuteInstallations
    add_column :cute_installations, :terminal, :integer, default: nil

    # Добавляем поле terminal к FidsInstallations
    add_column :fids_installations, :terminal, :integer, default: nil

    # Индексы для быстрого поиска по терминалу
    add_index :cute_installations, :terminal
    add_index :fids_installations, :terminal
  end
end
