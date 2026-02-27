# frozen_string_literal: true

class RepairReplyMailbox < ApplicationMailbox
  REPAIR_NUMBER_PATTERN = /REP-\d{4}-\d{3}/i

  def process
    repair_number = extract_repair_number
    unless repair_number
      bounce_with_notification("Не найден номер заявки в теме письма")
      return
    end

    batch = RepairBatch.find_by(repair_number: repair_number.upcase)
    unless batch
      bounce_with_notification("Не найден акт ремонта #{repair_number}")
      return
    end

    ticket_number = extract_ticket_number

    if ticket_number.present?
      update_batch_with_ticket(batch, ticket_number)
    else
      # Просто обновляем статус что ответ получен
      batch.update!(
        status: "in_progress",
        notes: append_note(batch.notes, "Получен ответ: #{mail.subject}")
      )
    end

    Rails.logger.info("RepairReplyMailbox: Обработано письмо для #{repair_number}")
  rescue StandardError => e
    Rails.logger.error("RepairReplyMailbox: Ошибка обработки — #{e.message}")
  end

  private

  def extract_repair_number
    subject = mail.subject.to_s
    match = subject.match(REPAIR_NUMBER_PATTERN)
    match ? match[0].upcase : nil
  end

  def extract_ticket_number
    body_text = mail.text_part&.body&.decoded || mail.body&.decoded || ""

    patterns = [
      /(?:заявка|ticket|номер заявки|№)\s*[#№]?\s*(\d{4,10})/i,
      /(?:request|req)\s*[#:]?\s*(\d{4,10})/i
    ]

    patterns.each do |pattern|
      match = body_text.match(pattern)
      return match[1] if match
    end

    nil
  end

  def update_batch_with_ticket(batch, ticket_number)
    ActiveRecord::Base.transaction do
      batch.update!(
        status: "in_progress",
        notes: append_note(batch.notes, "Номер заявки: #{ticket_number}")
      )

      batch.repair_batch_items.each do |item|
        item.update!(repair_ticket_number: ticket_number)

        # Обновляем repair_ticket_number на самом оборудовании
        equipment = item.equipment
        equipment&.update!(repair_ticket_number: ticket_number) if equipment
      end
    end
  end

  def append_note(existing, new_note)
    timestamp = Time.current.strftime("%d.%m.%Y %H:%M")
    [existing, "[#{timestamp}] #{new_note}"].compact_blank.join("\n")
  end

  def bounce_with_notification(reason)
    Rails.logger.warn("RepairReplyMailbox: #{reason} — #{mail.subject}")
  end
end
