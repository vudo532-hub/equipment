# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Создание тестовых данных..."

# Отключаем audited для seeds
Audited.auditing_enabled = false

# Обновляем существующих пользователей без имени/фамилии
User.where(first_name: [nil, '']).find_each do |u|
  u.update_columns(first_name: 'Пользователь', last_name: u.email.split('@').first.capitalize)
end

# Создание администратора (сильный пароль)
admin = User.find_or_initialize_by(email: "nn.sirotkin@svo.su")
admin.assign_attributes(
  password: "SecureAdmin1!",
  password_confirmation: "SecureAdmin1!",
  first_name: "Николай",
  last_name: "Сироткин",
  role: :admin
)
admin.save!
puts "Администратор: #{admin.email} (#{admin.full_name})"

# Создание тестового пользователя (сильный пароль)
user = User.find_or_initialize_by(email: "test@example.com")
user.assign_attributes(
  password: "Secure1Pass",
  password_confirmation: "Secure1Pass",
  first_name: "Тестовый",
  last_name: "Пользователь",
  role: :editor
)
user.save!
puts "Пользователь: #{user.email} (#{user.full_name})"

# Типы мест установки CUTE
cute_installation_types = ["Стойка регистрации", "Выход на посадку", "Транзит", "Негабарит", "VIP", "Комплектовка", "Камера хранения", "Учебный класс", "Склад", "ЦУИТ", "Комната", "Киоск самообслуживания"]

# Типы мест установки FIDS
fids_installation_types = ["Табло вылета", "Табло прилёта", "Информационный монитор", "Гейт-дисплей"]

# Типы оборудования CUTE
cute_equipment_types = [:computer, :monitor, :boarding_pass_printer, :baggage_tag_printer, :scanner, :gate_reader]

# Типы оборудования FIDS
fids_equipment_types = [:led_panel, :lcd_monitor, :media_player, :controller, :network_switch]

# Создание мест установки CUTE
puts "Создание мест установки CUTE..."
cute_installations = []
cute_installation_types.each_with_index do |type, i|
  installation = CuteInstallation.find_or_create_by!(
    user: user,
    identifier: "CUTE-#{format('%03d', i + 1)}"
  ) do |inst|
    inst.name = "#{type} #{i + 1}"
    inst.installation_type = type
  end
  cute_installations << installation
end
puts "Создано мест установки CUTE: #{cute_installations.count}"

# Создание мест установки FIDS
puts "Создание мест установки FIDS..."
fids_installations = []
8.times do |i|
  installation = FidsInstallation.find_or_create_by!(
    user: user,
    identifier: "FIDS-#{format('%03d', i + 1)}"
  ) do |inst|
    inst.name = "#{fids_installation_types.sample} #{i + 1}"
    inst.installation_type = fids_installation_types.sample
  end
  fids_installations << installation
end
puts "Создано мест установки FIDS: #{fids_installations.count}"

# Создание оборудования CUTE
puts "Создание оборудования CUTE..."
statuses = [:active, :active, :active, :maintenance]
cute_installations.each do |installation|
  # Для каждого места установки создаём 1-3 устройства разных типов
  equipment_count = rand(1..3)
  available_types = cute_equipment_types.shuffle
  
  equipment_count.times do |j|
    next if available_types.empty?
    equipment_type = available_types.pop
    
    CuteEquipment.find_or_create_by!(
      user: user,
      inventory_number: "INV-CUTE-#{installation.id}-#{format('%02d', j + 1)}"
    ) do |eq|
      eq.equipment_type = equipment_type
      eq.equipment_model = ["Dell OptiPlex 7090", "HP ProDesk 400", "Lenovo ThinkCentre", "HP LaserJet", "Zebra ZD421", "3M CR100"].sample
      eq.serial_number = "SN#{SecureRandom.hex(6).upcase}"
      eq.status = statuses.sample
      eq.cute_installation = installation
      eq.note = ["", "", "", "Требует проверки", "Новое оборудование", "Гарантия до 2027"].sample
    end
  end
end
puts "Создано оборудования CUTE: #{CuteEquipment.count}"

# Создание оборудования FIDS
puts "Создание оборудования FIDS..."
25.times do |i|
  FidsEquipment.find_or_create_by!(
    user: user,
    inventory_number: "INV-FIDS-#{format('%04d', i + 1)}"
  ) do |eq|
    eq.equipment_type = fids_equipment_types.sample
    eq.equipment_model = ["Samsung QM85R", "LG 55UH5F", "BrightSign XT1144", "Cisco 2960", "NEC MultiSync"].sample
    eq.serial_number = "SN#{SecureRandom.hex(6).upcase}"
    eq.status = statuses.sample
    eq.fids_installation = fids_installations.sample
    eq.note = ["", "", "", "Проверить подключение", "Заменить кабель"].sample
  end
end
puts "Создано оборудования FIDS: #{FidsEquipment.count}"

puts ""
puts "=" * 50
puts "Тестовые данные созданы!"
puts "=" * 50
puts ""
puts "Данные для входа:"
puts "  Администратор: nn.sirotkin@svo.su / SecureAdmin1!"
puts "  Тест-пользователь: test@example.com / Secure1Pass"
puts ""
puts "Статистика:"
puts "  Пользователей: #{User.count}"
puts "  Мест установки CUTE: #{CuteInstallation.count}"
puts "  Мест установки FIDS: #{FidsInstallation.count}"
puts "  Оборудования CUTE: #{CuteEquipment.count}"
puts "  Оборудования FIDS: #{FidsEquipment.count}"
puts "=" * 50
