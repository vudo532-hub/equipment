# frozen_string_literal: true

# Custom Audit model with JSON serialization
class Audit < Audited::Audit
  serialize :audited_changes, coder: JSON

  # Returns a human-readable description of the audited object
  def object_description
    return "#{auditable_type} ##{auditable_id}" unless auditable

    case auditable_type
    when "CuteEquipment", "FidsEquipment", "ZamarEquipment"
      auditable.equipment_model.presence || auditable.inventory_number
    when "CuteInstallation", "FidsInstallation", "ZamarInstallation"
      auditable.name
    else
      "#{auditable_type} ##{auditable_id}"
    end
  end

  # Returns a formatted array of changes for display, with humanized names and values
  def formatted_changes
    return [] unless audited_changes.present?
    audited_changes.reject { |field, _| 
      ["updated_at", "created_at", "last_action_date", "last_changed_by_id"].include?(field) || 
      (action == "create" && "user_id" == field)
    }.map do |field, change|
      model = auditable_type.safe_constantize
      attr_name = if model&.respond_to?(:human_attribute_name)
        model.human_attribute_name(field)
      else
        field.to_s.humanize
      end

      old_val = change.is_a?(Array) ? change[0] : nil
      new_val = change.is_a?(Array) ? change[1] : change

      old_human = humanize_value(old_val, field, model)
      new_human = humanize_value(new_val, field, model)

      {
        attr: attr_name,
        old: old_human,
        new: new_human
      }
    end
  end

  # Override audited_changes to return humanized values
  def audited_changes
    raw = super
    return raw unless raw.present?
    raw.map do |field, change|
      old, new = change.is_a?(Array) ? change : [nil, change]
      model = auditable_type.safe_constantize
      old_human = humanize_change_value(old, field, model)
      new_human = humanize_change_value(new, field, model)
      [field, [old_human, new_human]]
    end.to_h
  end

  private

  def humanize_change_value(value, field, model)
    return value unless model
    if model.defined_enums.key?(field)
      if value.is_a?(Integer)
        enum_hash = model.defined_enums[field]
        key = enum_hash.key(value)
        I18n.t("equipment_statuses.#{key}", default: key.to_s.humanize)
      elsif value.is_a?(String) && value =~ /^\d+$/
        enum_hash = model.defined_enums[field]
        key = enum_hash.key(value.to_i)
        I18n.t("equipment_statuses.#{key}", default: key.to_s.humanize)
      else
        value
      end
    elsif value.is_a?(Time) or value.is_a?(Date)
      I18n.l(value, format: :short)
    elsif value.is_a?(String) and value =~ /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/
      Time.parse(value).strftime("%d.%m.%Y %H:%M")
    else
      value
    end
  end

  def humanize_value(value, field, model)
    return "—" if value.blank?
    if model && model.defined_enums.key?(field)
      enum_hash = model.defined_enums[field]
      if value.is_a?(Integer)
        key = enum_hash.key(value)
        I18n.t("equipment_statuses.#{key}", default: key.to_s.humanize)
      elsif value.is_a?(String) && value =~ /^\d+$/
        key = enum_hash.key(value.to_i)
        I18n.t("equipment_statuses.#{key}", default: key.to_s.humanize)
      else
        value
      end
    elsif value.is_a?(Time) or value.is_a?(Date)
      I18n.l(value, format: :short)
    elsif value.is_a?(String) and value =~ /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/
      Time.parse(value).strftime("%d.%m.%Y %H:%M")
    else
      value
    end
  end
end
