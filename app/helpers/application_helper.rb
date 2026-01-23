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
end
