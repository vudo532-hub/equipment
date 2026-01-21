# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_01_21_130302) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "audits", force: :cascade do |t|
    t.integer "auditable_id"
    t.string "auditable_type"
    t.integer "associated_id"
    t.string "associated_type"
    t.integer "user_id"
    t.string "user_type"
    t.string "username"
    t.string "action"
    t.text "audited_changes"
    t.integer "version", default: 0
    t.string "comment"
    t.string "remote_address"
    t.string "request_uuid"
    t.datetime "created_at"
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "cute_equipments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "cute_installation_id"
    t.string "equipment_type", null: false
    t.string "equipment_model"
    t.string "inventory_number", null: false
    t.string "serial_number"
    t.integer "status", default: 0, null: false
    t.text "note"
    t.datetime "last_action_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cute_installation_id"], name: "index_cute_equipments_on_cute_installation_id"
    t.index ["equipment_type"], name: "index_cute_equipments_on_equipment_type"
    t.index ["inventory_number"], name: "index_cute_equipments_on_inventory_number"
    t.index ["last_action_date"], name: "index_cute_equipments_on_last_action_date"
    t.index ["serial_number"], name: "index_cute_equipments_on_serial_number"
    t.index ["status"], name: "index_cute_equipments_on_status"
    t.index ["user_id", "inventory_number"], name: "index_cute_equipments_on_user_id_and_inventory_number", unique: true
    t.index ["user_id"], name: "index_cute_equipments_on_user_id"
  end

  create_table "cute_installations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "installation_type", null: false
    t.string "identifier"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["installation_type"], name: "index_cute_installations_on_installation_type"
    t.index ["name"], name: "index_cute_installations_on_name"
    t.index ["user_id", "identifier"], name: "index_cute_installations_on_user_id_and_identifier", unique: true, where: "(identifier IS NOT NULL)"
    t.index ["user_id"], name: "index_cute_installations_on_user_id"
  end

  create_table "fids_equipments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "fids_installation_id"
    t.string "equipment_type", null: false
    t.string "equipment_model"
    t.string "inventory_number", null: false
    t.string "serial_number"
    t.integer "status", default: 0, null: false
    t.text "note"
    t.datetime "last_action_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["equipment_type"], name: "index_fids_equipments_on_equipment_type"
    t.index ["fids_installation_id"], name: "index_fids_equipments_on_fids_installation_id"
    t.index ["inventory_number"], name: "index_fids_equipments_on_inventory_number"
    t.index ["last_action_date"], name: "index_fids_equipments_on_last_action_date"
    t.index ["serial_number"], name: "index_fids_equipments_on_serial_number"
    t.index ["status"], name: "index_fids_equipments_on_status"
    t.index ["user_id", "inventory_number"], name: "index_fids_equipments_on_user_id_and_inventory_number", unique: true
    t.index ["user_id"], name: "index_fids_equipments_on_user_id"
  end

  create_table "fids_installations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "installation_type", null: false
    t.string "identifier"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["installation_type"], name: "index_fids_installations_on_installation_type"
    t.index ["name"], name: "index_fids_installations_on_name"
    t.index ["user_id", "identifier"], name: "index_fids_installations_on_user_id_and_identifier", unique: true, where: "(identifier IS NOT NULL)"
    t.index ["user_id"], name: "index_fids_installations_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "cute_equipments", "cute_installations"
  add_foreign_key "cute_equipments", "users"
  add_foreign_key "cute_installations", "users"
  add_foreign_key "fids_equipments", "fids_installations"
  add_foreign_key "fids_equipments", "users"
  add_foreign_key "fids_installations", "users"
end
