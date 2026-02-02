# frozen_string_literal: true

namespace :test_data do
  desc "Создать тестовые записи оборудования для всех систем"
  task create_equipments: :environment do
    puts "Создание тестовых данных оборудования..."

    # CUTE
    create_cute_test_data
    # FIDS
    create_fids_test_data
    # ZAMAR
    create_zamar_test_data

    puts "\n✅ Тестовые данные успешно созданы!"
    puts "   CUTE оборудование: #{CuteEquipment.count}"
    puts "   FIDS оборудование: #{FidsEquipment.count}"
    puts "   ZAMAR оборудование: #{ZamarEquipment.count}"
  end

  desc "Создать тестовые записи мест установки для всех систем"
  task create_installations: :environment do
    puts "Создание тестовых данных мест установки..."

    create_cute_installations
    create_fids_installations
    create_zamar_installations

    puts "\n✅ Тестовые данные мест установки успешно созданы!"
    puts "   CUTE места установки: #{CuteInstallation.count}"
    puts "   FIDS места установки: #{FidsInstallation.count}"
    puts "   ZAMAR места установки: #{ZamarInstallation.count}"
  end

  desc "Создать все тестовые данные"
  task create_all: [:create_installations, :create_equipments]

  private

  def self.create_cute_test_data
    puts "\nСоздание CUTE оборудования..."

    equipment_types = EquipmentType.where(system: "cute", active: true)
    installations = CuteInstallation.all
    statuses = [0, 1, 2, 3, 4, 5, 6] # active, maintenance, waiting_repair, etc.

    attrs = []
    200.times do |i|
      attrs << {
        equipment_type: rand(0..7),
        equipment_type_ref_id: equipment_types.sample&.id,
        equipment_model: "Test CUTE Model #{i + 1}",
        inventory_number: "CUTE-TEST-#{sprintf('%04d', i + 1)}",
        serial_number: "SN-CUTE-#{rand(10_000_000..99_999_999)}",
        status: statuses.sample,
        cute_installation_id: [nil, installations.sample&.id].sample,
        note: ["Тестовая запись", nil, "Примечание для тестирования"].sample,
        created_at: Time.current - rand(1..365).days,
        updated_at: Time.current
      }
    end

    CuteEquipment.insert_all(attrs)
    puts "  ✓ Создано 200 записей CUTE оборудования"
  end

  def self.create_fids_test_data
    puts "\nСоздание FIDS оборудования..."

    equipment_types = EquipmentType.where(system: "fids", active: true)
    installations = FidsInstallation.all
    statuses = [0, 1, 2, 3, 4, 5, 6]
    type_names = ["Монитор", "Контроллер", "LED панель", "LED контроллер", "Сервер"]

    attrs = []
    150.times do |i|
      attrs << {
        equipment_type: type_names.sample,
        equipment_type_ref_id: equipment_types.sample&.id,
        equipment_model: "Test FIDS Model #{i + 1}",
        inventory_number: "FIDS-TEST-#{sprintf('%04d', i + 1)}",
        serial_number: "SN-FIDS-#{rand(10_000_000..99_999_999)}",
        status: statuses.sample,
        fids_installation_id: [nil, installations.sample&.id].sample,
        note: ["Тестовая запись FIDS", nil].sample,
        created_at: Time.current - rand(1..365).days,
        updated_at: Time.current
      }
    end

    FidsEquipment.insert_all(attrs)
    puts "  ✓ Создано 150 записей FIDS оборудования"
  end

  def self.create_zamar_test_data
    puts "\nСоздание ZAMAR оборудования..."

    equipment_types = EquipmentType.where(system: "zamar", active: true)
    installations = ZamarInstallation.all
    statuses = [0, 1, 2, 3, 4, 5, 6]

    attrs = []
    100.times do |i|
      attrs << {
        equipment_type: rand(0..3),
        equipment_type_ref_id: equipment_types.sample&.id,
        equipment_model: "Test ZAMAR Model #{i + 1}",
        inventory_number: "ZAMAR-TEST-#{sprintf('%04d', i + 1)}",
        serial_number: "SN-ZAMAR-#{rand(10_000_000..99_999_999)}",
        status: statuses.sample,
        zamar_installation_id: [nil, installations.sample&.id].sample,
        note: ["Тестовая запись ZAMAR", nil].sample,
        created_at: Time.current - rand(1..365).days,
        updated_at: Time.current
      }
    end

    ZamarEquipment.insert_all(attrs)
    puts "  ✓ Создано 100 записей ZAMAR оборудования"
  end

  def self.create_cute_installations
    puts "\nСоздание CUTE мест установки..."

    installation_types = InstallationType.where(system: "cute", active: true)
    terminals = %w[terminal_a terminal_b terminal_c terminal_d terminal_e terminal_f]

    attrs = []
    50.times do |i|
      inst_type = installation_types.sample
      attrs << {
        name: "CUTE Место #{i + 1}",
        installation_type: inst_type&.name || "Стойка регистрации",
        installation_type_ref_id: inst_type&.id,
        terminal: terminals.sample,
        identifier: "CUTE-LOC-#{sprintf('%03d', i + 1)}",
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    CuteInstallation.insert_all(attrs)
    puts "  ✓ Создано 50 мест установки CUTE"
  end

  def self.create_fids_installations
    puts "\nСоздание FIDS мест установки..."

    installation_types = InstallationType.where(system: "fids", active: true)
    terminals = %w[terminal_a terminal_b terminal_c terminal_d terminal_e terminal_f]

    attrs = []
    40.times do |i|
      inst_type = installation_types.sample
      attrs << {
        name: "FIDS Место #{i + 1}",
        installation_type: inst_type&.name || "Табло",
        installation_type_ref_id: inst_type&.id,
        terminal: terminals.sample,
        identifier: "FIDS-LOC-#{sprintf('%03d', i + 1)}",
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    FidsInstallation.insert_all(attrs)
    puts "  ✓ Создано 40 мест установки FIDS"
  end

  def self.create_zamar_installations
    puts "\nСоздание ZAMAR мест установки..."

    installation_types = InstallationType.where(system: "zamar", active: true)
    terminals = %w[terminal_a terminal_b terminal_c terminal_d terminal_e terminal_f]

    attrs = []
    30.times do |i|
      inst_type = installation_types.sample
      attrs << {
        name: "ZAMAR Место #{i + 1}",
        installation_type: inst_type&.name || "DSM",
        installation_type_ref_id: inst_type&.id,
        terminal: terminals.sample,
        identifier: "ZAMAR-LOC-#{sprintf('%03d', i + 1)}",
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    ZamarInstallation.insert_all(attrs)
    puts "  ✓ Создано 30 мест установки ZAMAR"
  end
end
