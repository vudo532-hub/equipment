class ApplicationMailbox < ActionMailbox::Base
  # Маршрутизация входящей почты для ремонтных заявок
  # Совпадение по номеру заявки REP-XXXX-XXX в теме письма
  routing(/REP-\d{4}-\d{3}/i => :repair_reply)

  # Совпадение по ключевым словам
  routing(/repair|ремонт/i => :repair_reply)
end
