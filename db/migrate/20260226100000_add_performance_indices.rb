# frozen_string_literal: true

class AddPerformanceIndices < ActiveRecord::Migration[8.0]
  def change
    # === Audits: composite indices for filtered queries ===
    # Audit logs filter by auditable_type + created_at (system filter + ordering)
    add_index :audits, [:auditable_type, :created_at],
              name: "index_audits_on_auditable_type_and_created_at"

    # Audit logs filter by user_id + created_at (non-admin view + ordering)
    add_index :audits, [:user_id, :created_at],
              name: "index_audits_on_user_id_and_created_at"

    # Audit logs filter by action + created_at
    add_index :audits, [:action, :created_at],
              name: "index_audits_on_action_and_created_at"

    # === Equipment: composite indices for common filter combinations ===
    # Status + created_at for ordered filtered listing (all 3 subsystems)
    add_index :cute_equipments, [:status, :created_at],
              name: "index_cute_equipments_on_status_and_created_at"
    add_index :fids_equipments, [:status, :created_at],
              name: "index_fids_equipments_on_status_and_created_at"
    add_index :zamar_equipments, [:status, :created_at],
              name: "index_zamar_equipments_on_status_and_created_at"

    # Status + last_action_date for default ordered listing
    add_index :cute_equipments, [:status, :last_action_date],
              name: "index_cute_equipments_on_status_and_last_action_date"
    add_index :fids_equipments, [:status, :last_action_date],
              name: "index_fids_equipments_on_status_and_last_action_date"
    add_index :zamar_equipments, [:status, :last_action_date],
              name: "index_zamar_equipments_on_status_and_last_action_date"

    # equipment_type_ref_id + status for filtered queries with new type system
    add_index :cute_equipments, [:equipment_type_ref_id, :status],
              name: "index_cute_equipments_on_type_ref_and_status"
    add_index :fids_equipments, [:equipment_type_ref_id, :status],
              name: "index_fids_equipments_on_type_ref_and_status"
    add_index :zamar_equipments, [:equipment_type_ref_id, :status],
              name: "index_zamar_equipments_on_type_ref_and_status"

    # === Installations: composite index for type + terminal filtering ===
    add_index :cute_installations, [:installation_type, :terminal],
              name: "index_cute_installations_on_type_and_terminal"
    add_index :fids_installations, [:installation_type, :terminal],
              name: "index_fids_installations_on_type_and_terminal"
    add_index :zamar_installations, [:installation_type, :terminal],
              name: "index_zamar_installations_on_type_and_terminal"

    # === Repair: composite indices for common queries ===
    add_index :repair_batches, [:status, :created_at],
              name: "index_repair_batches_on_status_and_created_at"
    add_index :repair_batch_items, [:repair_batch_id, :system],
              name: "index_repair_batch_items_on_batch_and_system"
  end
end
