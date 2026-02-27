# frozen_string_literal: true

# Настройки email для ремонтных заявок
Rails.application.config.repair_email_to = ENV.fetch("REPAIR_EMAIL_TO", "repair@example.com")
Rails.application.config.repair_email_reply_to = ENV.fetch("REPAIR_EMAIL_REPLY_TO", "equipment-repair@example.com")
Rails.application.config.repair_email_from = ENV.fetch("REPAIR_EMAIL_FROM", "equipment@example.com")
