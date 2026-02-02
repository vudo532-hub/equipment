# frozen_string_literal: true

# Seed для типов оборудования и мест установки
# Запуск: bin/rails db:seed:equipment_types

puts "Создание типов оборудования..."

# CUTE Equipment Types
cute_equipment_types = [
  { name: "Сканер", code: "scanner", position: 1 },
  { name: "Принтер посадочных талонов", code: "boarding_pass_printer", position: 2 },
  { name: "Принтер багажных бирок", code: "baggage_tag_printer", position: 3 },
  { name: "Клавиатура", code: "keyboard", position: 4 },
  { name: "Гейт-ридер", code: "gate_reader", position: 5 },
  { name: "Принтер полётных документов", code: "flight_document_printer", position: 6 },
  { name: "Монитор", code: "monitor", position: 7 },
  { name: "Компьютер", code: "computer", position: 8 },
  { name: "С примечанием", code: "s_primechaniem", position: 99 }
]

cute_equipment_types.each do |attrs|
  EquipmentType.find_or_create_by!(system: "cute", code: attrs[:code]) do |et|
    et.name = attrs[:name]
    et.position = attrs[:position]
    et.active = true
  end
end
puts "  ✓ CUTE: #{cute_equipment_types.size} типов оборудования"

# FIDS Equipment Types
fids_equipment_types = [
  { name: "Монитор", code: "monitor", position: 1 },
  { name: "Контроллер", code: "controller", position: 2 },
  { name: "LED панель", code: "led_panel", position: 3 },
  { name: "LED контроллер", code: "led_controller", position: 4 },
  { name: "Сервер", code: "server", position: 5 },
  { name: "С примечанием", code: "s_primechaniem", position: 99 }
]

fids_equipment_types.each do |attrs|
  EquipmentType.find_or_create_by!(system: "fids", code: attrs[:code]) do |et|
    et.name = attrs[:name]
    et.position = attrs[:position]
    et.active = true
  end
end
puts "  ✓ FIDS: #{fids_equipment_types.size} типов оборудования"

# ZAMAR Equipment Types
zamar_equipment_types = [
  { name: "Планшет", code: "tablet", position: 1 },
  { name: "Сканер", code: "scanner", position: 2 },
  { name: "Ворота", code: "gates", position: 3 },
  { name: "С примечанием", code: "s_primechaniem", position: 99 }
]

zamar_equipment_types.each do |attrs|
  EquipmentType.find_or_create_by!(system: "zamar", code: attrs[:code]) do |et|
    et.name = attrs[:name]
    et.position = attrs[:position]
    et.active = true
  end
end
puts "  ✓ ZAMAR: #{zamar_equipment_types.size} типов оборудования"

puts "\nСоздание типов мест установки..."

# CUTE Installation Types
cute_installation_types = [
  { name: "Стойка регистрации ООО", code: "check_in_desk_ooo", position: 1 },
  { name: "Стойка регистрации ДМД", code: "check_in_desk_dmd", position: 2 },
  { name: "Гейт ООО", code: "gate_ooo", position: 3 },
  { name: "Гейт ДМД", code: "gate_dmd", position: 4 },
  { name: "Офис", code: "office", position: 5 },
  { name: "Комната CUTE", code: "cute_room", position: 6 },
  { name: "Стойка пересадки", code: "transfer_desk", position: 7 },
  { name: "Стойка Lost & Found", code: "lost_found_desk", position: 8 },
  { name: "Стойка сверхнормативного багажа", code: "excess_baggage_desk", position: 9 },
  { name: "Стойка бизнес зала", code: "business_lounge_desk", position: 10 },
  { name: "Стойка VIP", code: "vip_desk", position: 11 },
  { name: "Киоск ООО", code: "kiosk_ooo", position: 12 }
]

cute_installation_types.each do |attrs|
  InstallationType.find_or_create_by!(system: "cute", code: attrs[:code]) do |it|
    it.name = attrs[:name]
    it.position = attrs[:position]
    it.active = true
  end
end
puts "  ✓ CUTE: #{cute_installation_types.size} типов мест установки"

# FIDS Installation Types
fids_installation_types = [
  { name: "Стойка регистрации", code: "check_in_desk", position: 1 },
  { name: "Выход на посадку", code: "boarding_gate", position: 2 },
  { name: "Табло", code: "display_board", position: 3 },
  { name: "Кластер", code: "cluster", position: 4 },
  { name: "Зона выдачи багажа", code: "baggage_claim", position: 5 },
  { name: "Комплектовка", code: "assembly", position: 6 },
  { name: "Бизнес зал", code: "business_lounge", position: 7 },
  { name: "VIP", code: "vip", position: 8 },
  { name: "Транзит", code: "transit", position: 9 },
  { name: "Зона досмотра", code: "security_zone", position: 10 },
  { name: "Комната", code: "room", position: 11 }
]

fids_installation_types.each do |attrs|
  InstallationType.find_or_create_by!(system: "fids", code: attrs[:code]) do |it|
    it.name = attrs[:name]
    it.position = attrs[:position]
    it.active = true
  end
end
puts "  ✓ FIDS: #{fids_installation_types.size} типов мест установки"

# ZAMAR Installation Types
zamar_installation_types = [
  { name: "DSM", code: "dsm", position: 1 },
  { name: "DBA", code: "dba", position: 2 },
  { name: "SBDO", code: "sbdo", position: 3 }
]

zamar_installation_types.each do |attrs|
  InstallationType.find_or_create_by!(system: "zamar", code: attrs[:code]) do |it|
    it.name = attrs[:name]
    it.position = attrs[:position]
    it.active = true
  end
end
puts "  ✓ ZAMAR: #{zamar_installation_types.size} типов мест установки"

puts "\n✅ Seed завершён!"
puts "   Типы оборудования: #{EquipmentType.count}"
puts "   Типы мест установки: #{InstallationType.count}"
