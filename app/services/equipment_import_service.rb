# frozen_string_literal: true

require "csv"
require "roo"

class EquipmentImportService
  attr_reader :imported, :skipped, :errors

  def initialize(file, system)
    @file = file
    @system = system
    @imported = 0
    @skipped = 0
    @errors = []
  end

  def import
    case file_type
    when :csv
      import_from_csv
    when :xlsx
      import_from_xlsx
    else
      return { success: false, error: "Неподдерживаемый формат файла. Используйте CSV или XLSX." }
    end

    {
      success: true,
      imported: @imported,
      skipped: @skipped,
      errors: @errors.first(10) # Показываем только первые 10 ошибок
    }
  rescue StandardError => e
    { success: false, error: "Ошибка при импорте: #{e.message}" }
  end

  private

  def file_type
    return :csv if @file.original_filename&.end_with?(".csv")
    return :xlsx if @file.original_filename&.end_with?(".xlsx")
    nil
  end

  def import_from_csv
    rows = []

    CSV.foreach(@file.path, headers: true, col_sep: ";", encoding: "UTF-8") do |row|
      rows << row.to_h
    end

    process_rows(rows)
  end

  def import_from_xlsx
    xlsx = Roo::Spreadsheet.open(@file.path)
    headers = xlsx.row(1).map(&:to_s).map(&:strip)
    rows = []

    (2..xlsx.last_row).each do |i|
      row_data = xlsx.row(i)
      rows << Hash[headers.zip(row_data.map { |v| v.to_s.strip })]
    end

    process_rows(rows)
  end

  def process_rows(rows)
    equipment_attrs = []

    rows.each_with_index do |row, index|
      row_number = index + 2 # +2 потому что индекс начинается с 0 и пропускаем заголовок

      equipment_type_name = row["Тип оборудования"]&.strip
      model = row["Модель"]&.strip
      inventory_number = row["Инвентарный номер"]&.strip
      serial_number = row["Серийный номер"]&.strip
      terminal = row["Терминал"]&.strip
      installation_type_name = row["Тип места установки"]&.strip
      installation_name = row["Название места"]&.strip
      status = row["Статус"]&.strip
      note = row["Примечание"]&.strip

      # Проверка обязательных полей
      if model.blank? || inventory_number.blank?
        @skipped += 1
        @errors << "Строка #{row_number}: пропущена — отсутствует модель или инвентарный номер"
        next
      end

      # Проверка уникальности инвентарного номера
      if equipment_exists?(inventory_number)
        @skipped += 1
        @errors << "Строка #{row_number}: пропущена — инвентарный номер '#{inventory_number}' уже существует"
        next
      end

      # Находим или создаём тип оборудования
      equipment_type = find_or_create_equipment_type(equipment_type_name)

      # Находим или создаём место установки
      installation = nil
      if terminal.present? && installation_name.present?
        installation_type = find_or_create_installation_type(installation_type_name) if installation_type_name.present?
        installation = find_or_create_installation(terminal, installation_type, installation_name)
      end

      equipment_attrs << {
        equipment_type_ref_id: equipment_type&.id,
        equipment_model: model,
        inventory_number: inventory_number,
        serial_number: serial_number.presence || "N/A",
        status: map_status(status),
        note: note,
        "#{installation_key}_id": installation&.id,
        created_at: Time.current,
        updated_at: Time.current
      }.compact
    end

    # Batch insert для производительности
    if equipment_attrs.any?
      equipment_class.insert_all(equipment_attrs)
      @imported = equipment_attrs.size
    end
  end

  def equipment_exists?(inventory_number)
    equipment_class.exists?(inventory_number: inventory_number)
  end

  def find_or_create_equipment_type(name)
    return nil if name.blank?

    EquipmentType.find_or_create_by!(system: @system, name: name) do |et|
      et.code = name.parameterize.underscore
      et.position = EquipmentType.where(system: @system).maximum(:position).to_i + 1
      et.active = true
    end
  end

  def find_or_create_installation_type(name)
    return nil if name.blank?

    InstallationType.find_or_create_by!(system: @system, name: name) do |it|
      it.code = name.parameterize.underscore
      it.position = InstallationType.where(system: @system).maximum(:position).to_i + 1
      it.active = true
    end
  end

  def find_or_create_installation(terminal, installation_type, name)
    terminal_value = map_terminal(terminal)
    return nil if terminal_value.blank?

    installation_class.find_or_create_by!(
      terminal: terminal_value,
      name: name
    ) do |inst|
      inst.installation_type = installation_type&.name || "Другое"
      inst.installation_type_ref = installation_type
    end
  end

  def equipment_class
    case @system
    when "cute" then CuteEquipment
    when "fids" then FidsEquipment
    when "zamar" then ZamarEquipment
    else
      raise "Неизвестная система: #{@system}"
    end
  end

  def installation_class
    case @system
    when "cute" then CuteInstallation
    when "fids" then FidsInstallation
    when "zamar" then ZamarInstallation
    else
      raise "Неизвестная система: #{@system}"
    end
  end

  def installation_key
    case @system
    when "cute" then "cute_installation"
    when "fids" then "fids_installation"
    when "zamar" then "zamar_installation"
    end
  end

  def map_terminal(terminal_text)
    return nil if terminal_text.blank?

    case terminal_text.upcase.strip
    when "A", "ТЕРМИНАЛ A" then "terminal_a"
    when "B", "ТЕРМИНАЛ B" then "terminal_b"
    when "C", "ТЕРМИНАЛ C" then "terminal_c"
    when "D", "ТЕРМИНАЛ D" then "terminal_d"
    when "E", "ТЕРМИНАЛ E" then "terminal_e"
    when "F", "ТЕРМИНАЛ F" then "terminal_f"
    else
      terminal_text.downcase.gsub(/\s+/, "_")
    end
  end

  def map_status(status_text)
    case status_text&.downcase&.strip
    when "в работе", "активное", "active", "активен"
      0 # active
    when "на обслуживании", "обслуживание", "maintenance"
      1 # maintenance
    when "ожидает ремонта", "ремонт", "repair", "waiting_repair"
      2 # waiting_repair
    when "готово к отправке", "ready", "ready_to_dispatch"
      3 # ready_to_dispatch
    when "списано", "decommissioned"
      4 # decommissioned
    when "передано", "transferred"
      5 # transferred
    when "с примечанием", "with_note"
      6 # with_note
    else
      0 # default: active
    end
  end
end
