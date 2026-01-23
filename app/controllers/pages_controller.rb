class PagesController < ApplicationController
  before_action :authenticate_user!

  def dashboard
    # =========================================
    # 1. Общее количество оборудования по системам
    # =========================================
    @cute_count = CuteEquipment.count
    @fids_count = FidsEquipment.count
    @zamar_count = ZamarEquipment.count
    @total_equipment = @cute_count + @fids_count + @zamar_count

    # Структура: { "CUTE" => count, "FIDS" => count, "ZAMAR" => count }
    @equipment_by_system = {
      "CUTE" => @cute_count,
      "FIDS" => @fids_count,
      "ZAMAR" => @zamar_count
    }

    # =========================================
    # 2. Оборудование по системам И терминалам
    # =========================================
    @terminals = %w[A B C D E F]
    
    # CUTE по терминалам (через cute_installation)
    @cute_by_terminal = CuteEquipment
      .joins(:cute_installation)
      .group("cute_installations.terminal")
      .count
      .transform_keys { |k| terminal_letter(k) }

    # FIDS по терминалам (через fids_installation)
    @fids_by_terminal = FidsEquipment
      .joins(:fids_installation)
      .group("fids_installations.terminal")
      .count
      .transform_keys { |k| terminal_letter(k) }

    # ZAMAR по терминалам (через zamar_installation)
    @zamar_by_terminal = ZamarEquipment
      .joins(:zamar_installation)
      .group("zamar_installations.terminal")
      .count
      .transform_keys { |k| terminal_letter(k) }

    # Оборудование без терминала (на складе или не привязано)
    @cute_warehouse = CuteEquipment.where(cute_installation_id: nil).count
    @fids_warehouse = FidsEquipment.where(fids_installation_id: nil).count
    @zamar_warehouse = ZamarEquipment.where(zamar_installation_id: nil).count
    @total_warehouse = @cute_warehouse + @fids_warehouse + @zamar_warehouse

    # =========================================
    # 3. Оборудование по типам в каждой системе
    # =========================================
    @cute_by_type = CuteEquipment.group(:equipment_type).count
    @zamar_by_type = ZamarEquipment.group(:equipment_type).count
    # FIDS: equipment_type - это строка, не enum
    @fids_by_type = FidsEquipment.group(:equipment_type).count

    # =========================================
    # 4. МАТРИЦА: Типы оборудования по терминалам (для CUTE)
    # =========================================
    @cute_type_terminal_matrix = CuteEquipment
      .joins(:cute_installation)
      .group(:equipment_type, "cute_installations.terminal")
      .count

    @zamar_type_terminal_matrix = ZamarEquipment
      .joins(:zamar_installation)
      .group(:equipment_type, "zamar_installations.terminal")
      .count

    # =========================================
    # 5. Статистика по статусам
    # =========================================
    @cute_by_status = CuteEquipment.group(:status).count
    @fids_by_status = FidsEquipment.group(:status).count
    @zamar_by_status = ZamarEquipment.group(:status).count

    # =========================================
    # 6. Количество мест установки
    # =========================================
    @cute_installations_count = CuteInstallation.count
    @fids_installations_count = FidsInstallation.count
    @zamar_installations_count = ZamarInstallation.count
    @total_installations_count = @cute_installations_count + @fids_installations_count + @zamar_installations_count

    # =========================================
    # 7. Недавно добавленное оборудование
    # =========================================
    cute_recent = CuteEquipment.includes(:cute_installation).order(created_at: :desc).limit(5).map do |e|
      { equipment: e, system: "CUTE", color: "blue", path: cute_equipment_path(e) }
    end

    fids_recent = FidsEquipment.includes(:fids_installation).order(created_at: :desc).limit(5).map do |e|
      { equipment: e, system: "FIDS", color: "green", path: fids_equipment_path(e) }
    end

    zamar_recent = ZamarEquipment.includes(:zamar_installation).order(created_at: :desc).limit(5).map do |e|
      { equipment: e, system: "ZAMAR", color: "purple", path: zamar_equipment_path(e) }
    end

    @recent_equipments = (cute_recent + fids_recent + zamar_recent)
      .sort_by { |e| e[:equipment].created_at }
      .reverse
      .first(5)
  end

  private

  # Преобразование terminal_a -> "A", terminal_b -> "B" и т.д.
  def terminal_letter(terminal_value)
    return "?" if terminal_value.blank?
    # terminal_value может быть integer или string "terminal_a"
    if terminal_value.is_a?(Integer)
      %w[A B C D E F][terminal_value] || "?"
    else
      terminal_value.to_s.split("_").last.upcase
    end
  end
end
