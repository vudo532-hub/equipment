# frozen_string_literal: true

module EquipmentModalHelper
  # Determines equipment type from controller or context
  def equipment_type_from_controller
    case controller_name
    when 'cute_equipments'
      'cute'
    when 'fids_equipments'
      'fids'
    when 'zamar_equipments'
      'zamar'
    else
      nil
    end
  end

  # Get human-readable equipment system name
  def equipment_system_name(type)
    case type
    when 'cute'
      'CUTE'
    when 'fids'
      'FIDS'
    when 'zamar'
      'ZAMAR'
    else
      'Оборудование'
    end
  end

  # Generate modal title for add operation
  def modal_title_for_new(type)
    "Добавить новое оборудование (#{equipment_system_name(type)})"
  end

  # Generate modal title for edit operation
  def modal_title_for_edit(equipment, type)
    model = equipment.equipment_model.presence || "Без модели"
    "Редактировать #{equipment_system_name(type)} оборудование: #{model}"
  end

  # Get form path helper for equipment type
  def form_path_for_equipment(equipment, type)
    case type
    when 'cute'
      equipment.persisted? ? cute_equipment_path(equipment) : cute_equipments_path
    when 'fids'
      equipment.persisted? ? fids_equipment_path(equipment) : fids_equipments_path
    when 'zamar'
      equipment.persisted? ? zamar_equipment_path(equipment) : zamar_equipments_path
    end
  end

  # Get model class for equipment type
  def model_class_for_equipment(type)
    case type
    when 'cute'
      CuteEquipment
    when 'fids'
      FidsEquipment
    when 'zamar'
      ZamarEquipment
    end
  end

  # Get form partial path for equipment type
  def form_partial_path(type)
    case type
    when 'cute'
      'cute_equipments/form'
    when 'fids'
      'fids_equipments/form'
    when 'zamar'
      'zamar_equipments/form'
    end
  end

  # Generate link for opening modal to add equipment
  def add_equipment_modal_link(type, classes = "")
    path = case type
    when 'cute'
      new_cute_equipment_path
    when 'fids'
      new_fids_equipment_path
    when 'zamar'
      new_zamar_equipment_path
    end

    link_to path,
            class: classes,
            data: { turbo_frame: 'equipment-modal-frame' },
            aria_label: "Добавить #{equipment_system_name(type)} оборудование" do
      yield
    end
  end

  # Generate link for opening modal to edit equipment
  def edit_equipment_modal_link(equipment, type, classes = "")
    path = case type
    when 'cute'
      edit_cute_equipment_path(equipment)
    when 'fids'
      edit_fids_equipment_path(equipment)
    when 'zamar'
      edit_zamar_equipment_path(equipment)
    end

    link_to path,
            class: classes,
            data: { turbo_frame: 'equipment-modal-frame' },
            aria_label: "Редактировать оборудование" do
      yield
    end
  end
end
