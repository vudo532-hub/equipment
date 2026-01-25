class RepairsController < ApplicationController
  before_action :authenticate_user!

  def index
    # Собираем оборудование в статусе "В ремонт" из всех систем
    @cute_equipments = CuteEquipment.where(status: :maintenance).includes(:cute_installation, :last_changed_by)
    @fids_equipments = FidsEquipment.where(status: :maintenance).includes(:fids_installation, :last_changed_by)
    @zamar_equipments = ZamarEquipment.where(status: :maintenance).includes(:zamar_installation, :last_changed_by)

    # Фильтрация по терминалу
    if params[:terminal].present?
      @cute_equipments = @cute_equipments.joins(:cute_installation).where(cute_installations: { terminal: params[:terminal] })
      @fids_equipments = @fids_equipments.joins(:fids_installation).where(fids_installations: { terminal: params[:terminal] })
      @zamar_equipments = @zamar_equipments.joins(:zamar_installation).where(zamar_installations: { terminal: params[:terminal] })
    end

    # Фильтрация по системе
    case params[:system]
    when "cute"
      @fids_equipments = FidsEquipment.none
      @zamar_equipments = ZamarEquipment.none
    when "fids"
      @cute_equipments = CuteEquipment.none
      @zamar_equipments = ZamarEquipment.none
    when "zamar"
      @cute_equipments = CuteEquipment.none
      @fids_equipments = FidsEquipment.none
    end

    # Фильтрация по типу оборудования
    if params[:equipment_type].present?
      @cute_equipments = @cute_equipments.where(equipment_type: params[:equipment_type])
      @fids_equipments = @fids_equipments.where(equipment_type: params[:equipment_type])
      @zamar_equipments = @zamar_equipments.where(equipment_type: params[:equipment_type])
    end

    # Объединяем в один массив для отображения
    @all_equipments = []
    
    @cute_equipments.find_each do |eq|
      @all_equipments << {
        id: eq.id,
        system: "CUTE",
        type: "CuteEquipment",
        terminal: eq.cute_installation&.terminal_name,
        installation: eq.cute_installation&.name,
        equipment_type: eq.equipment_type_text,
        model: eq.equipment_model,
        inventory_number: eq.inventory_number,
        serial_number: eq.serial_number,
        status: eq.status_text,
        note: eq.note,
        last_action_date: eq.last_action_date,
        last_changed_by: eq.last_changed_by&.full_name
      }
    end

    @fids_equipments.find_each do |eq|
      @all_equipments << {
        id: eq.id,
        system: "FIDS",
        type: "FidsEquipment",
        terminal: eq.fids_installation&.terminal_name,
        installation: eq.fids_installation&.name,
        equipment_type: eq.equipment_type,
        model: eq.equipment_model,
        inventory_number: eq.inventory_number,
        serial_number: eq.serial_number,
        status: eq.status_text,
        note: eq.note,
        last_action_date: eq.last_action_date,
        last_changed_by: eq.last_changed_by&.full_name
      }
    end

    @zamar_equipments.find_each do |eq|
      @all_equipments << {
        id: eq.id,
        system: "Zamar",
        type: "ZamarEquipment",
        terminal: eq.zamar_installation&.terminal_name,
        installation: eq.zamar_installation&.name,
        equipment_type: eq.equipment_type_text,
        model: eq.equipment_model,
        inventory_number: eq.inventory_number,
        serial_number: eq.serial_number,
        status: eq.status_text,
        note: eq.note,
        last_action_date: eq.last_action_date,
        last_changed_by: eq.last_changed_by&.full_name
      }
    end

    # Сортировка по дате последнего действия
    @all_equipments.sort_by! { |eq| eq[:last_action_date] || Time.at(0) }.reverse!

    # Список терминалов для фильтра
    @terminals = CuteInstallation.terminal_a.model.attribute_types["terminal"].serialize.to_a rescue %w[terminal_a terminal_b terminal_c terminal_d terminal_e terminal_f]

    # Список типов оборудования для фильтра
    @equipment_types = collect_equipment_types
  end

  def create_batch
    equipment_ids = params[:equipment_ids] || []
    
    if equipment_ids.empty?
      return render json: { success: false, error: "Не выбрано оборудование" }, status: :bad_request
    end

    ActiveRecord::Base.transaction do
      @batch = RepairBatch.create!(
        user: current_user,
        equipment_count: equipment_ids.length,
        status: "sent"
      )

      equipment_ids.each do |item|
        equipment_type = item[:type]
        equipment_id = item[:id]
        
        equipment = equipment_type.constantize.find(equipment_id)
        
        # Получаем данные места установки
        installation = case equipment_type
                       when "CuteEquipment" then equipment.cute_installation
                       when "FidsEquipment" then equipment.fids_installation
                       when "ZamarEquipment" then equipment.zamar_installation
                       end

        # Создаем запись в акте
        @batch.repair_batch_items.create!(
          equipment_type: equipment_type,
          equipment_id: equipment_id,
          system: equipment_type.gsub("Equipment", "").upcase.gsub("CUTE", "CUTE").gsub("FIDS", "FIDS").gsub("ZAMAR", "Zamar"),
          serial_number: equipment.serial_number,
          model: equipment.equipment_model,
          inventory_number: equipment.inventory_number,
          terminal: installation&.terminal_name,
          installation_name: installation&.name,
          note: equipment.note
        )

        # Меняем статус на "Ожидается из ремонта"
        equipment.update!(
          status: :waiting_repair,
          last_changed_by: current_user,
          last_action_date: Time.current
        )
      end
    end

    render json: { 
      success: true, 
      message: "Акт №#{@batch.repair_number} создан! #{@batch.equipment_count} единиц оборудования отправлено в ремонт.",
      batch_id: @batch.id,
      repair_number: @batch.repair_number
    }
  rescue ActiveRecord::RecordInvalid => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  rescue StandardError => e
    render json: { success: false, error: "Ошибка при создании акта: #{e.message}" }, status: :internal_server_error
  end

  def show
    @batch = RepairBatch.includes(:repair_batch_items, :user).find(params[:id])
    @items = @batch.repair_batch_items.order(:system, :model)
  end

  def export_to_excel
    @batch = RepairBatch.includes(:repair_batch_items, :user).find(params[:id])
    
    respond_to do |format|
      format.xlsx {
        response.headers['Content-Disposition'] = "attachment; filename=\"Акт_ремонта_#{@batch.repair_number}.xlsx\""
      }
    end
  end

  def history
    @q = RepairBatchItem.includes(:repair_batch).ransack(params[:q])
    base_items = @q.result(distinct: true)
    
    # Фильтрация по серийному номеру
    if params[:serial_number].present?
      base_items = base_items.where(serial_number: params[:serial_number])
      @serial_stats = calculate_serial_stats(params[:serial_number])
    end

    # Фильтрация по датам
    if params[:date_from].present?
      base_items = base_items.where("repair_batch_items.created_at >= ?", params[:date_from].to_date.beginning_of_day)
    end
    if params[:date_to].present?
      base_items = base_items.where("repair_batch_items.created_at <= ?", params[:date_to].to_date.end_of_day)
    end

    # Для отображения - с сортировкой
    @items = base_items.order(created_at: :desc)

    # Статистика - без сортировки для корректной работы GROUP BY
    @total_count = base_items.count
    @unique_serials = base_items.distinct.count(:serial_number)
    @top_models = base_items.reorder(nil).group(:model).count.sort_by { |_, v| -v }.first(5)
  end

  private

  def collect_equipment_types
    types = []
    types += CuteEquipment.where(status: :maintenance).distinct.pluck(:equipment_type).map { |t| ["CUTE: #{I18n.t("cute_equipment_types.#{t}", default: t)}", "cute_#{t}"] }
    types += FidsEquipment.where(status: :maintenance).distinct.pluck(:equipment_type).map { |t| ["FIDS: #{t}", "fids_#{t}"] }
    types += ZamarEquipment.where(status: :maintenance).distinct.pluck(:equipment_type).map { |t| ["Zamar: #{I18n.t("zamar_equipment_types.#{t}", default: t)}", "zamar_#{t}"] }
    types
  end

  def calculate_serial_stats(serial_number)
    items = RepairBatchItem.where(serial_number: serial_number).includes(:repair_batch).order(created_at: :desc)
    {
      total_repairs: items.count,
      dates: items.map { |i| { date: i.created_at, batch_number: i.repair_batch.repair_number } }
    }
  end
end
