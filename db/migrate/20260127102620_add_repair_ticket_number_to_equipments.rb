class AddRepairTicketNumberToEquipments < ActiveRecord::Migration[8.0]
  def change
    add_column :cute_equipments, :repair_ticket_number, :string
    add_column :fids_equipments, :repair_ticket_number, :string
    add_column :zamar_equipments, :repair_ticket_number, :string
  end
end
