class ZamarInstallationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_installation, only: [:show, :edit, :update, :destroy, :search_equipment, :attach_equipment, :detach_equipment]
  before_action :require_delete_permission, only: [:destroy]

  def index
    @q = ZamarInstallation.ransack(params[:q])
    @q.sorts = "name asc" if @q.sorts.empty?
    @installations = @q.result(distinct: true).includes(:zamar_equipments)
  end

  def show
    @equipments = @installation.zamar_equipments.ordered.limit(10)
  end

  def new
    @installation = ZamarInstallation.new
  end

  def create
    @installation = ZamarInstallation.new(installation_params)
    @installation.user = current_user

    if @installation.save
      redirect_to zamar_installations_path, notice: t("flash.created", resource: ZamarInstallation.model_name.human)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @installation.update(installation_params)
      redirect_to zamar_installations_path, notice: t("flash.updated", resource: ZamarInstallation.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @installation.destroy
    redirect_to zamar_installations_path, notice: t("flash.deleted", resource: ZamarInstallation.model_name.human)
  end

  # AJAX: Поиск оборудования по серийному номеру
  def search_equipment
    serial_number = params[:serial_number]&.strip
    
    if serial_number.blank?
      return render json: { success: false, error: "Введите серийный номер" }, status: :bad_request
    end

    equipment = ZamarEquipment.find_by(serial_number: serial_number, zamar_installation_id: nil)

    if equipment
      render json: {
        success: true,
        equipment: {
          id: equipment.id,
          equipment_type: equipment.equipment_type,
          equipment_type_human: equipment.human_equipment_type,
          equipment_model: equipment.equipment_model,
          serial_number: equipment.serial_number,
          inventory_number: equipment.inventory_number,
          status: equipment.status,
          status_human: equipment.human_status
        }
      }
    else
      existing = ZamarEquipment.find_by(serial_number: serial_number)
      if existing
        render json: { success: false, error: "Оборудование уже привязано к месту установки" }, status: :not_found
      else
        render json: { success: false, error: "Оборудование с таким серийным номером не найдено" }, status: :not_found
      end
    end
  end

  # AJAX: Привязка оборудования к месту установки
  def attach_equipment
    equipment = ZamarEquipment.find_by(id: params[:equipment_id], zamar_installation_id: nil)

    if equipment.nil?
      return render json: { success: false, error: "Оборудование не найдено или уже привязано" }, status: :not_found
    end

    equipment.zamar_installation = @installation
    equipment.user = current_user

    if equipment.save
      render json: { success: true, message: "Оборудование успешно привязано" }
    else
      render json: { success: false, error: "Ошибка при привязке оборудования" }, status: :unprocessable_entity
    end
  end

  # AJAX: Отвязка оборудования от места установки
  def detach_equipment
    equipment = @installation.zamar_equipments.find_by(id: params[:equipment_id])

    if equipment.nil?
      return render json: { success: false, error: "Оборудование не найдено" }, status: :not_found
    end

    equipment.zamar_installation = nil
    equipment.user = current_user

    if equipment.save
      render json: { success: true, message: "Оборудование успешно отвязанно" }
    else
      render json: { success: false, error: "Ошибка при отвязке оборудования" }, status: :unprocessable_entity
    end
  end

  private

  def set_installation
    @installation = ZamarInstallation.find(params[:id])
  end

  def installation_params
    params.require(:zamar_installation).permit(:name, :installation_type, :identifier, :terminal)
  end
end
