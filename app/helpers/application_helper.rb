module ApplicationHelper
  # Truncate note with tooltip
  def truncate_note(note, max_length: 50)
    return "—" if note.blank?
    
    if note.length > max_length
      content_tag(:span, 
                  truncate(note, length: max_length), 
                  title: note, 
                  class: "cursor-help",
                  data: { controller: "tooltip" })
    else
      note
    end
  end

  # Форматирование даты на русском
  def format_date_ru(date)
    return "—" if date.blank?
    I18n.l(date, format: :long)
  end

  # Форматирование даты и времени на русском
  def format_datetime_ru(datetime)
    return "—" if datetime.blank?
    I18n.l(datetime, format: :long)
  end

  # Название терминала по букве
  def terminal_display_name(letter)
    return "—" if letter.blank?
    "Терминал #{letter}"
  end

  # Преобразование ключа терминала в букву
  def terminal_key_to_letter(key)
    return "?" if key.blank?
    if key.is_a?(Integer)
      %w[A B C D E F][key] || "?"
    else
      key.to_s.split("_").last.upcase
    end
  end

  # Название типа оборудования CUTE
  def cute_equipment_type_name(type_key)
    return "—" if type_key.blank?
    # type_key может быть integer (из group) или string
    type_str = type_key.is_a?(Integer) ? CuteEquipment.equipment_types.key(type_key) : type_key.to_s
    I18n.t("cute_equipment_types.#{type_str}", default: type_str.to_s.humanize)
  end

  # Название типа оборудования ZAMAR
  def zamar_equipment_type_name(type_key)
    return "—" if type_key.blank?
    type_str = type_key.is_a?(Integer) ? ZamarEquipment.equipment_types.key(type_key) : type_key.to_s
    I18n.t("zamar_equipment_types.#{type_str}", default: type_str.to_s.upcase)
  end

  # Название статуса оборудования
  def equipment_status_name(status_key)
    return "—" if status_key.blank?
    status_str = if status_key.is_a?(Integer)
      CuteEquipment.statuses.key(status_key) || status_key.to_s
    else
      status_key.to_s
    end
    I18n.t("equipment_statuses.#{status_str}", default: status_str.humanize)
  end

  # Цвет статуса для badge
  def status_badge_color(status_key)
    status_str = status_key.is_a?(Integer) ? CuteEquipment.statuses.key(status_key) : status_key.to_s
    case status_str
    when "active" then "bg-green-100 text-green-800"
    when "maintenance" then "bg-yellow-100 text-yellow-800"
    when "waiting_repair" then "bg-orange-100 text-orange-800"
    when "ready_to_dispatch" then "bg-blue-100 text-blue-800"
    when "decommissioned" then "bg-red-100 text-red-800"
    when "transferred" then "bg-purple-100 text-purple-800"
    when "with_note" then "bg-gray-100 text-gray-800"
    else "bg-gray-100 text-gray-800"
    end
  end

  # Render status badge
  def render_status_badge(status)
    status_str = status.is_a?(Integer) ? CuteEquipment.statuses.key(status) : status.to_s
    status_text = case status_str
    when "active" then "В работе"
    when "maintenance" then "В ремонт"
    when "waiting_repair" then "Ожидает ремонта"
    when "ready_to_dispatch" then "Готово к выдаче"
    when "decommissioned" then "Списание"
    when "transferred" then "Передано"
    when "with_note" then "С примечанием"
    else status_str.humanize
    end

    content_tag(:span, status_text, class: "px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full #{status_badge_color(status)}")
  end

  # Форматирование аудит-лога
  def format_audit_action(audit, model_class = nil)
    case audit.action
    when "create"
      "Создано оборудование"
    when "update"
      format_audit_changes(audit, model_class)
    when "destroy"
      "Удалено оборудование"
    else
      audit.action.humanize
    end
  end

  def format_audit_changes(audit, model_class = nil)
    changes = audit.audited_changes
    return "Обновлено" if changes.blank?
    
    descriptions = []
    
    changes.each do |field, values|
      old_value, new_value = values.is_a?(Array) ? values : [nil, values]
      
      field_name = translate_field_name(field)
      formatted_old = format_audit_value(field, old_value, model_class)
      formatted_new = format_audit_value(field, new_value, model_class)
      
      if old_value.present? && new_value.present?
        descriptions << "Изменено: #{field_name} — #{formatted_old} → #{formatted_new}"
      elsif old_value.present?
        descriptions << "Удалено: #{field_name} — #{formatted_old}"
      else
        descriptions << "Установлено: #{field_name} — #{formatted_new}"
      end
    end
    
    descriptions.join("; ")
  end

  def translate_field_name(field)
    translations = {
      "status" => "Статус",
      "equipment_type" => "Тип оборудования",
      "equipment_model" => "Модель",
      "serial_number" => "Серийный номер",
      "inventory_number" => "Инвентарный номер",
      "note" => "Примечание",
      "last_action_date" => "Дата последнего действия",
      "last_changed_by_id" => "Пользователь",
      "cute_installation_id" => "Место установки",
      "fids_installation_id" => "Место установки",
      "zamar_installation_id" => "Место установки"
    }
    translations[field] || field.humanize
  end

  def format_audit_value(field, value, model_class = nil)
    return "пусто" if value.blank?
    
    case field
    when "status"
      I18n.t("equipment_statuses.#{value}", default: value.to_s.humanize)
    when "equipment_type"
      I18n.t("equipment_types.#{value}", default: value.to_s.humanize)
    when "cute_installation_id"
      installation = CuteInstallation.find_by(id: value)
      installation ? format_installation_with_terminal(installation) : "ID: #{value}"
    when "fids_installation_id"
      installation = FidsInstallation.find_by(id: value)
      installation ? format_installation_with_terminal(installation) : "ID: #{value}"
    when "zamar_installation_id"
      installation = ZamarInstallation.find_by(id: value)
      installation ? format_installation_with_terminal(installation) : "ID: #{value}"
    when "last_changed_by_id"
      user = User.find_by(id: value)
      user ? user.full_name : "ID: #{value}"
    when "last_action_date"
      value.is_a?(String) ? value : format_datetime_ru(value)
    else
      value.to_s.truncate(50)
    end
  end

  def format_installation_with_terminal(installation)
    if installation.respond_to?(:terminal_name) && installation.terminal.present?
      "#{installation.terminal_name}, #{installation.name}"
    else
      installation.name
    end
  end

  def audit_action_icon(action)
    case action
    when "create"
      '<svg class="w-4 h-4 text-green-500" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-11a1 1 0 10-2 0v2H7a1 1 0 100 2h2v2a1 1 0 102 0v-2h2a1 1 0 100-2h-2V7z" clip-rule="evenodd"/></svg>'.html_safe
    when "update"
      '<svg class="w-4 h-4 text-blue-500" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M4 2a1 1 0 011 1v2.101a7.002 7.002 0 0111.601 2.566 1 1 0 11-1.885.666A5.002 5.002 0 005.999 7H9a1 1 0 010 2H4a1 1 0 01-1-1V3a1 1 0 011-1zm.008 9.057a1 1 0 011.276.61A5.002 5.002 0 0014.001 13H11a1 1 0 110-2h5a1 1 0 011 1v5a1 1 0 11-2 0v-2.101a7.002 7.002 0 01-11.601-2.566 1 1 0 01.61-1.276z" clip-rule="evenodd"/></svg>'.html_safe
    when "destroy"
      '<svg class="w-4 h-4 text-red-500" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z" clip-rule="evenodd"/></svg>'.html_safe
    else
      '<svg class="w-4 h-4 text-gray-500" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd"/></svg>'.html_safe
    end
  end

  # Описание объекта в audit log
  def audit_object_description(audit)
    auditable = audit.auditable
    return audit.auditable_type if auditable.nil?

    case audit.auditable_type
    when "CuteEquipment"
      equipment_description(auditable, "CUTE")
    when "FidsEquipment"
      equipment_description(auditable, "FIDS")
    when "ZamarEquipment"
      equipment_description(auditable, "Zamar")
    when "CuteInstallation"
      installation_description(auditable, "CUTE")
    when "FidsInstallation"
      installation_description(auditable, "FIDS")
    when "ZamarInstallation"
      installation_description(auditable, "Zamar")
    else
      auditable.try(:name) || audit.auditable_type
    end
  end

  def equipment_description(equipment, system)
    type_name = case system
                when "CUTE"
                  equipment.respond_to?(:equipment_type_text) ? equipment.equipment_type_text : equipment.equipment_type
                when "Zamar"
                  zamar_equipment_type_name(equipment.equipment_type)
                else
                  equipment.equipment_type
                end
    model = equipment.equipment_model.presence || "—"
    serial = equipment.serial_number.presence || "—"
    "[#{system}] #{type_name} / #{model} (S/N: #{serial})"
  end

  def installation_description(installation, system)
    terminal_info = if installation.terminal.present?
                      "Терминал #{installation.terminal_name}"
                    else
                      "Без терминала"
                    end
    "[#{system}] #{installation.name} (#{terminal_info})"
  end

  # Форматированный вывод изменений в audit log
  def formatted_audit_changes(audit)
    changes = audit.audited_changes
    return "" if changes.blank?

    result = []
    changes.each do |field, values|
      old_value, new_value = values.is_a?(Array) ? values : [nil, values]
      
      field_label = human_field_name(field)
      old_display = format_change_value(field, old_value, audit.auditable_type)
      new_display = format_change_value(field, new_value, audit.auditable_type)

      if audit.action == "create"
        result << "#{field_label}: #{new_display}" if new_value.present?
      elsif audit.action == "destroy"
        result << "#{field_label}: #{old_display}" if old_value.present?
      else
        result << content_tag(:span, class: "inline-block") do
          safe_join([
            content_tag(:span, "#{field_label}: ", class: "font-medium"),
            content_tag(:span, old_display, class: "text-gray-500 line-through"),
            content_tag(:span, " → ", class: "mx-1 text-gray-400"),
            content_tag(:span, new_display, class: "text-green-700 font-medium")
          ])
        end
      end
    end
    
    safe_join(result, content_tag(:br))
  end

  def human_field_name(field)
    {
      "status" => "Статус",
      "equipment_type" => "Тип",
      "equipment_model" => "Модель",
      "serial_number" => "С/Н",
      "inventory_number" => "Инв. №",
      "note" => "Примечание",
      "name" => "Название",
      "installation_type" => "Тип места",
      "identifier" => "Идентификатор",
      "terminal" => "Терминал",
      "cute_installation_id" => "Место установки",
      "fids_installation_id" => "Место установки",
      "zamar_installation_id" => "Место установки",
      "last_changed_by_id" => "Изменил",
      "last_action_date" => "Дата действия"
    }[field] || field.humanize
  end

  def format_change_value(field, value, auditable_type)
    return "(пусто)" if value.blank?

    case field
    when "status"
      I18n.t("equipment_statuses.#{value}", default: value.to_s.humanize)
    when "equipment_type"
      case auditable_type
      when "CuteEquipment"
        I18n.t("cute_equipment_types.#{value}", default: value.to_s.humanize)
      when "ZamarEquipment"
        I18n.t("zamar_equipment_types.#{value}", default: value.to_s.upcase)
      else
        value.to_s
      end
    when "terminal"
      "Терминал #{value.to_s.split('_').last.upcase}"
    when "cute_installation_id"
      installation = CuteInstallation.find_by(id: value)
      installation ? installation.name : "(Место ##{value})"
    when "fids_installation_id"
      installation = FidsInstallation.find_by(id: value)
      installation ? installation.name : "(Место ##{value})"
    when "zamar_installation_id"
      installation = ZamarInstallation.find_by(id: value)
      installation ? installation.name : "(Место ##{value})"
    when "last_changed_by_id"
      user = User.find_by(id: value)
      user ? user.full_name : "(Пользователь ##{value})"
    when "last_action_date"
      if value.is_a?(String)
        Time.parse(value).strftime("%d.%m.%Y %H:%M") rescue value
      else
        value.strftime("%d.%m.%Y %H:%M")
      end
    else
      value.to_s.truncate(100)
    end
  end

  # Helper methods for equipment modal forms
  def equipment_options_for_select(equipment_type)
    case equipment_type
    when 'cute'
      [
        ["Принтер посадочных талонов", "boarding_pass_printer"],
        ["Принтер багажных бирок", "baggage_tag_printer"],
        ["Клавиатура", "keyboard"],
        ["Сканер", "scanner"],
        ["Считыватель на гейте", "gate_reader"],
        ["Принтер полётной документации", "flight_document_printer"],
        ["Монитор", "monitor"],
        ["Компьютер", "computer"],
        ["Прочее", "other"]
      ]
    when 'fids'
      [
        ["Монитор FIDS", "fids_monitor"],
        ["Сервер FIDS", "fids_server"],
        ["Принтер FIDS", "fids_printer"],
        ["Сеть FIDS", "fids_network"],
        ["Прочее", "other"]
      ]
    when 'zamar'
      [
        ["Принтер ZAMAR", "zamar_printer"],
        ["Сканер ZAMAR", "zamar_scanner"],
        ["Терминал ZAMAR", "zamar_terminal"],
        ["Сервер ZAMAR", "zamar_server"],
        ["Прочее", "other"]
      ]
    else
      []
    end
  end

  def status_options_for_select
    [
      ["В работе", "active"],
      ["В ремонт", "maintenance"],
      ["Ожидается из ремонта", "waiting_repair"],
      ["Готово к выдачи", "ready_to_dispatch"],
      ["Списание", "decommissioned"],
      ["Передано в другое место", "transferred"],
      ["С примечанием", "with_note"]
    ]
  end

  def equipment_model_field(equipment_type)
    case equipment_type
    when 'cute' then :equipment_model
    when 'fids' then :equipment_model
    when 'zamar' then :equipment_model
    else :equipment_model
    end
  end

  def installation_field(equipment_type)
    case equipment_type
    when 'cute' then :cute_installation_id
    when 'fids' then :fids_installation_id
    when 'zamar' then :zamar_installation_id
    else :installation_id
    end
  end

  def installation_label(equipment_type)
    case equipment_type
    when 'cute' then "Место установки"
    when 'fids' then "Место установки"
    when 'zamar' then "Место установки"
    else "Место установки"
    end
  end

  def equipment_model_field(equipment_type)
    case equipment_type
    when 'cute' then :equipment_model
    when 'fids' then :equipment_model
    when 'zamar' then :equipment_model
    else :equipment_model
    end
  end

  def equipment_options_for_select(equipment_type)
    case equipment_type
    when 'cute'
      CuteEquipment.equipment_types.map { |key, value| [I18n.t("cute_equipment_types.#{key}", default: key.to_s.humanize), key] }
    when 'fids'
      [] # FIDS uses text field for equipment_type
    when 'zamar'
      [] # ZAMAR uses text field for equipment_type
    else
      []
    end
  end

  # Flash message helpers
  def flash_class(type)
    case type.to_s
    when "success" then "bg-green-50 border-l-4 border-green-400 p-4"
    when "error" then "bg-red-50 border-l-4 border-red-400 p-4"
    when "warning" then "bg-yellow-50 border-l-4 border-yellow-400 p-4"
    when "info" then "bg-blue-50 border-l-4 border-blue-400 p-4"
    else "bg-gray-50 border-l-4 border-gray-400 p-4"
    end
  end

  def flash_icon(type)
    case type.to_s
    when "success"
      '<svg class="h-5 w-5 text-green-400" viewBox="0 0 20 20" fill="currentColor">
        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
      </svg>'.html_safe
    when "error"
      '<svg class="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 00-1.414 1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
      </svg>'.html_safe
    when "warning"
      '<svg class="h-5 w-5 text-yellow-400" viewBox="0 0 20 20" fill="currentColor">
        <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/>
      </svg>'.html_safe
    else
      '<svg class="h-5 w-5 text-blue-400" viewBox="0 0 20 20" fill="currentColor">
        <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd"/>
      </svg>'.html_safe
    end
  end

  def flash_text_color(type)
    case type.to_s
    when "success" then "text-green-800"
    when "error" then "text-red-800"
    when "warning" then "text-yellow-800"
    when "info" then "text-blue-800"
    else "text-gray-800"
    end
  end

  def flash_bg_hover_color(type)
    case type.to_s
    when "success" then "green-100"
    when "error" then "red-100"
    when "warning" then "yellow-100"
    when "info" then "blue-100"
    else "gray-100"
    end
  end

  def flash_ring_color(type)
    case type.to_s
    when "success" then "green-500"
    when "error" then "red-500"
    when "warning" then "yellow-500"
    when "info" then "blue-500"
    else "gray-500"
    end
  end
end
