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

# Создание администратора
admin = User.find_or_initialize_by(email: "nn.sirotkin@svo.su")
admin.assign_attributes(
  password: "Admin123!",
  password_confirmation: "Admin123!",
  first_name: "Николай",
  last_name: "Сироткин",
  role: :admin
)
admin.save!
puts "Администратор: #{admin.email} (#{admin.full_name})"

# Создание тестового пользователя
user = User.find_or_initialize_by(email: "test@example.com")
user.assign_attributes(
  password: "password123",
  password_confirmation: "password123",
  first_name: "Тестовый",
  last_name: "Пользователь",
  role: :editor
)
user.save!
puts "Пользователь: #{user.email} (#{user.full_name})"

# Типы мест установки CUTE
cute_installation_types = ["Стойка регистрации", "Гейт", "Киоск самообслуживания", "Бизнес-зал"]

# Типы мест установки FIDS
fids_installation_types = ["Табло вылета", "Табло прилёта", "Информационный монитор", "Гейт-дисплей"]

# Типы оборудования CUTE
cute_equipment_types = ["Компьютер", "Монитор", "Принтер посадочных", "Принтер багажных бирок", "Сканер паспортов", "Считыватель карт"]

# Типы оборудования FIDS
fids_equipment_types = ["LED-панель", "LCD-монитор", "Медиаплеер", "Контроллер", "Сетевой коммутатор"]

# Создание мест установки CUTE
puts "Создание мест установки CUTE..."
cute_installations = []
10.times do |i|
  installation = CuteInstallation.find_or_create_by!(
    user: user,
    identifier: "CUTE-#{format('%03d', i + 1)}"
  ) do |inst|
    inst.name = "#{cute_installation_types.sample} #{i + 1}"
    inst.installation_type = cute_installation_types.sample
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
statuses = [:active, :active, :active, :inactive, :maintenance]
30.times do |i|
  CuteEquipment.find_or_create_by!(
    user: user,
    inventory_number: "INV-CUTE-#{format('%04d', i + 1)}"
  ) do |eq|
    eq.equipment_type = cute_equipment_types.sample
    eq.equipment_model = ["Dell OptiPlex 7090", "HP ProDesk 400", "Lenovo ThinkCentre", "HP LaserJet", "Zebra ZD421", "3M CR100"].sample
    eq.serial_number = "SN#{SecureRandom.hex(6).upcase}"
    eq.status = statuses.sample
    eq.cute_installation = cute_installations.sample
    eq.note = ["", "", "", "Требует проверки", "Новое оборудование", "Гарантия до 2027"].sample
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
puts "  Email: test@example.com"
puts "  Пароль: password123"
puts ""
puts "Статистика:"
puts "  Пользователей: #{User.count}"
puts "  Мест установки CUTE: #{CuteInstallation.count}"
puts "  Мест установки FIDS: #{FidsInstallation.count}"
puts "  Оборудования CUTE: #{CuteEquipment.count}"
puts "  Оборудования FIDS: #{FidsEquipment.count}"
puts "=" * 50
