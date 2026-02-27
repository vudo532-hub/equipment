# frozen_string_literal: true

class RepairMailer < ApplicationMailer
  default from: -> { Rails.application.config.repair_email_from }

  def repair_request(repair_batch)
    @batch = repair_batch
    @items = repair_batch.repair_batch_items.order(:id)

    mail(
      to: Rails.application.config.repair_email_to,
      reply_to: Rails.application.config.repair_email_reply_to,
      subject: "Заявка на ремонт #{@batch.repair_number}"
    )
  end
end
