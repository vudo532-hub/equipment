class AddRepairTicketNumberToRepairBatchItems < ActiveRecord::Migration[8.0]
  def change
    add_column :repair_batch_items, :repair_ticket_number, :string
  end
end
