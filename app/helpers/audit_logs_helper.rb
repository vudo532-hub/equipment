# frozen_string_literal: true

module AuditLogsHelper
  # Маппинг названий полей на русский
  FIELD_TRANSLATIONS = {
    "equipment_type" => "Тип оборудования",
    "equipment_type_ref_id" => "Тип оборудования",
    "equipment_model" => "Модель",
    "inventory_number" => "Инвентарный номер",
    "serial_number" => "Серийный номер",
    "status" => "Статус",
    "note" => "Примечание",
    "cute_installation_id" => "Место установки",
    "fids_installation_id" => "Место установки",
    "zamar_installation_id" => "Место установки",
    "installation_type" => "Тип места установки",
    "installation_type_ref_id" => "Тип места установки",
    "name" => "Название",
    "terminal" => "Терминал",
    "identifier" => "Идентификатор",
    "last_changed_by_id" => "Изменено пользователем",
    "last_action_date" => "Дата последнего действия",
    "repair_ticket_number" => "Номер заявки на ремонт"
  }.freeze

  # Маппинг статусов оборудования на русский
  STATUS_TRANSLATIONS = {
    "active" => "В работе",
    "0" => "В работе",
    0 => "В работе",
    "maintenance" => "На обслуживании",
    "1" => "На обслуживании",
    1 => "На обслуживании",
    "waiting_repair" => "Ожидает ремонта",
    "2" => "Ожидает ремонта",
    2 => "Ожидает ремонта",
    "ready_to_dispatch" => "Готово к отправке",
    "3" => "Готово к отправке",
    3 => "Готово к отправке",
    "decommissioned" => "Списано",
    "4" => "Списано",
    4 => "Списано",
    "transferred" => "Передано",
    "5" => "Передано",
    5 => "Передано",
    "with_note" => "С примечанием",
    "6" => "С примечанием",
    6 => "С примечанием"
  }.freeze

  # Маппинг терминалов
  TERMINAL_TRANSLATIONS = {
    "terminal_a" => "Терминал A",
    "0" => "Терминал A",
    0 => "Терминал A",
    "terminal_b" => "Терминал B",
    "1" => "Терминал B",
    1 => "Терминал B",
    "terminal_c" => "Терминал C",
    "2" => "Терминал C",
    2 => "Терминал C",
    "terminal_d" => "Терминал D",
    "3" => "Терминал D",
    3 => "Терминал D",
    "terminal_e" => "Терминал E",
    "4" => "Терминал E",
    4 => "Терминал E",
    "terminal_f" => "Терминал F",
    "5" => "Терминал F",
    5 => "Терминал F"
  }.freeze

  # Маппинг типов оборудования CUTE
  CUTE_EQUIPMENT_TYPE_TRANSLATIONS = {
    "boarding_pass_printer" => "Принтер посадочных талонов",
    "0" => "Принтер посадочных талонов",
    0 => "Принтер посадочных талонов",
    "baggage_tag_printer" => "Принтер багажных бирок",
    "1" => "Принтер багажных бирок",
    1 => "Принтер багажных бирок",
    "keyboard" => "Клавиатура",
    "2" => "Клавиатура",
    2 => "Клавиатура",
    "scanner" => "Сканер",
    "3" => "Сканер",
    3 => "Сканер",
    "gate_reader" => "Гейт-ридер",
    "4" => "Гейт-ридер",
    4 => "Гейт-ридер",
    "flight_document_printer" => "Принтер полётных документов",
    "5" => "Принтер полётных документов",
    5 => "Принтер полётных документов",
    "monitor" => "Монитор",
    "6" => "Монитор",
    6 => "Монитор",
    "computer" => "Компьютер",
    "7" => "Компьютер",
    7 => "Компьютер",
    "other" => "Другое",
    "99" => "Другое",
    99 => "Другое"
  }.freeze

  def translate_field_name(field)
    FIELD_TRANSLATIONS[field] || field.humanize
  end

  def translate_field_value(field, value, auditable_type = nil)
    return "(пусто)" if value.blank?

    case field
    when "status"
      STATUS_TRANSLATIONS[value] || value.to_s
    when "terminal"
      TERMINAL_TRANSLATIONS[value] || value.to_s
    when "equipment_type"
      if auditable_type&.include?("Cute")
        CUTE_EQUIPMENT_TYPE_TRANSLATIONS[value] || value.to_s
      else
        value.to_s.humanize
      end
    when "cute_installation_id", "fids_installation_id", "zamar_installation_id"
      find_installation_name(field, value)
    when "equipment_type_ref_id"
      EquipmentType.find_by(id: value)&.name || value.to_s
    when "installation_type_ref_id"
      InstallationType.find_by(id: value)&.name || value.to_s
    when "last_changed_by_id"
      User.find_by(id: value)&.full_name || value.to_s
    else
      value.to_s
    end
  end

  def format_audit_changes(audit, model_class = nil)
    return content_tag(:span, "—", class: "text-gray-400") if audit.audited_changes.blank?

    changes_html = []

    # Пропускаем старые поля если есть соответствующие ref_id поля
    audited_changes = audit.audited_changes.dup
    if audited_changes.key?("equipment_type") && audited_changes.key?("equipment_type_ref_id")
      audited_changes.delete("equipment_type")
    end
    if audited_changes.key?("installation_type") && audited_changes.key?("installation_type_ref_id")
      audited_changes.delete("installation_type")
    end

    audited_changes.each do |field, change|
      # Пропускаем технические поля
      next if %w[updated_at created_at user_id last_changed_by_id last_action_date].include?(field)

      field_name = translate_field_name(field)

      if change.is_a?(Array)
        old_value = translate_field_value(field, change[0], audit.auditable_type)
        new_value = translate_field_value(field, change[1], audit.auditable_type)

        changes_html << content_tag(:div, class: "mb-1") do
          safe_join([
            content_tag(:span, "#{field_name}: ", class: "font-medium text-gray-700"),
            content_tag(:span, old_value, class: "text-red-600 line-through"),
            " → ",
            content_tag(:span, new_value, class: "text-green-600")
          ])
        end
      else
        value = translate_field_value(field, change, audit.auditable_type)
        changes_html << content_tag(:div, class: "mb-1") do
          safe_join([
            content_tag(:span, "#{field_name}: ", class: "font-medium text-gray-700"),
            content_tag(:span, value, class: "text-green-600")
          ])
        end
      end
    end

    if changes_html.empty?
      content_tag(:span, "—", class: "text-gray-400")
    else
      safe_join(changes_html)
    end
  end

  def auditable_display_name(audit)
    return "Удалён" unless audit.auditable

    case audit.auditable_type
    when "CuteEquipment"
      "#{audit.auditable.equipment_type_text} — #{audit.auditable.inventory_number}"
    when "FidsEquipment"
      "#{audit.auditable.equipment_type} — #{audit.auditable.inventory_number}"
    when "ZamarEquipment"
      "#{audit.auditable.equipment_type_text} — #{audit.auditable.inventory_number}"
    when "CuteInstallation", "FidsInstallation", "ZamarInstallation"
      "#{audit.auditable.terminal_name || '—'} — #{audit.auditable.name}"
    else
      "#{audit.auditable_type} ##{audit.auditable_id}"
    end
  rescue StandardError
    "#{audit.auditable_type} ##{audit.auditable_id}"
  end

  def model_type_name(auditable_type)
    case auditable_type
    when "CuteEquipment" then "CUTE Оборудование"
    when "FidsEquipment" then "FIDS Оборудование"
    when "ZamarEquipment" then "ZAMAR Оборудование"
    when "CuteInstallation" then "CUTE Место установки"
    when "FidsInstallation" then "FIDS Место установки"
    when "ZamarInstallation" then "ZAMAR Место установки"
    when "RepairBatch" then "Партия ремонта"
    when "RepairBatchItem" then "Элемент партии ремонта"
    when "Import" then "Импорт"
    else
      auditable_type.to_s.underscore.humanize
    end
  end

  # Возвращает только название системы
  def system_name(auditable_type)
    case auditable_type
    when /^Cute/ then "CUTE"
    when /^Fids/ then "FIDS"
    when /^Zamar/ then "ZAMAR"
    when "RepairBatch", "RepairBatchItem" then "Ремонт"
    when "Import" then "Импорт"
    else
      "—"
    end
  end

  # Двухстрочное отображение объекта
  def auditable_display_two_lines(audit)
    return content_tag(:span, "Удалён", class: "text-gray-400") unless audit.auditable

    case audit.auditable_type
    when "CuteEquipment", "FidsEquipment", "ZamarEquipment"
      model = audit.auditable.equipment_model.presence || "—"
      serial = audit.auditable.serial_number.presence || "—"
      safe_join([
        content_tag(:div, model, class: "font-medium text-gray-900"),
        content_tag(:div, serial, class: "text-xs text-gray-500")
      ])
    when "CuteInstallation", "FidsInstallation", "ZamarInstallation"
      terminal = audit.auditable.terminal_name.presence || "—"
      name = audit.auditable.name.presence || "—"
      safe_join([
        content_tag(:div, terminal, class: "font-medium text-gray-900"),
        content_tag(:div, name, class: "text-xs text-gray-500")
      ])
    else
      content_tag(:span, "#{audit.auditable_type} ##{audit.auditable_id}", class: "text-gray-500")
    end
  rescue StandardError
    content_tag(:span, "#{audit.auditable_type} ##{audit.auditable_id}", class: "text-gray-400")
  end

  def action_badge(action)
    case action
    when "create"
      content_tag(:span, "Создание", class: "px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800")
    when "update"
      content_tag(:span, "Изменение", class: "px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-blue-100 text-blue-800")
    when "destroy"
      content_tag(:span, "Удаление", class: "px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-red-100 text-red-800")
    else
      content_tag(:span, action.humanize, class: "px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-gray-100 text-gray-800")
    end
  end

  private

  def find_installation_name(field, id)
    return "(пусто)" if id.blank?

    installation = case field
                   when "cute_installation_id"
                     CuteInstallation.find_by(id: id)
                   when "fids_installation_id"
                     FidsInstallation.find_by(id: id)
                   when "zamar_installation_id"
                     ZamarInstallation.find_by(id: id)
                   end

    installation&.name || "ID: #{id}"
  end
end
