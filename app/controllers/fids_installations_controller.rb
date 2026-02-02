class FidsInstallationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_installation, only: [:show, :edit, :update, :destroy, :search_equipment, :attach_equipment, :detach_equipment]
  before_action :require_delete_permission, only: [:destroy]

  def index
    @q = FidsInstallation.ransack(params[:q])
    @q.sorts = "name asc" if @q.sorts.empty?
    @installations = @q.result(distinct: true).includes(:fids_equipments)
  end

  def show
    @equipments = @installation.fids_equipments.ordered.limit(10)
    
    # История оборудования (привязка/отвязка) для этого места установки
    @equipment_history = Audit.where(auditable_type: "FidsEquipment")
                              .where("audited_changes::text LIKE ?", "%fids_installation_id%")
                              .order(created_at: :desc)
                              .limit(100)
                              .select { |audit| 
                                changes = audit.read_attribute(:audited_changes)
                                if changes.is_a?(Hash) && changes["fids_installation_id"].is_a?(Array)
                                  old_val, new_val = changes["fids_installation_id"]
                                  old_val == @installation.id || new_val == @installation.id
                                else
                                  false
                                end
                              }
                              .first(20)
  end

  def new
    @installation = FidsInstallation.new
    
    if turbo_frame_request?
      render partial: "modal_form", locals: { installation: @installation }
    end
  end

  def create
    @installation = FidsInstallation.new(installation_params)
    @installation.user = current_user

    if @installation.save
      if turbo_frame_request?
        redirect_to fids_installations_path, notice: t("flash.created", resource: FidsInstallation.model_name.human)
      else
        redirect_to fids_installations_path, notice: t("flash.created", resource: FidsInstallation.model_name.human)
      end
    else
      if turbo_frame_request?
        render partial: "modal_form", locals: { installation: @installation }, status: :unprocessable_entity
      else
        render :new, status: :unprocessable_entity
      end
    end
  end

  def edit
    if turbo_frame_request?
      render partial: "modal_form", locals: { installation: @installation }
    end
  end

  def update
    if @installation.update(installation_params)
      if turbo_frame_request?
        redirect_to fids_installations_path, notice: t("flash.updated", resource: FidsInstallation.model_name.human)
      else
        redirect_to fids_installations_path, notice: t("flash.updated", resource: FidsInstallation.model_name.human)
      end
    else
      if turbo_frame_request?
        render partial: "modal_form", locals: { installation: @installation }, status: :unprocessable_entity
      else
        render :edit, status: :unprocessable_entity
      end
    end
  end

  def destroy
    @installation.destroy
    redirect_to fids_installations_path, notice: t("flash.deleted", resource: FidsInstallation.model_name.human)
  end

  # AJAX: Поиск оборудования по серийному номеру
  def search_equipment
    serial_number = params[:serial_number]&.strip
    
    if serial_number.blank?
      return render json: { success: false, error: "Введите серийный номер" }, status: :bad_request
    end

    equipment = FidsEquipment.find_by(serial_number: serial_number, fids_installation_id: nil)

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
      existing = FidsEquipment.find_by(serial_number: serial_number)
      if existing
        render json: { success: false, error: "Оборудование уже привязано к месту установки" }, status: :not_found
      else
        render json: { success: false, error: "Оборудование с таким серийным номером не найдено" }, status: :not_found
      end
    end
  end

  # AJAX: Привязка оборудования к месту установки
  def attach_equipment
    equipment = FidsEquipment.find_by(id: params[:equipment_id], fids_installation_id: nil)

    if equipment.nil?
      return render json: { success: false, error: "Оборудование не найдено или уже привязано" }, status: :not_found
    end

    equipment.fids_installation = @installation
    equipment.user = current_user

    if equipment.save
      render json: { success: true, message: "Оборудование успешно привязано" }
    else
      render json: { success: false, error: "Ошибка при привязке оборудования" }, status: :unprocessable_entity
    end
  end

  # AJAX: Отвязка оборудования от места установки
  def detach_equipment
    equipment = @installation.fids_equipments.find_by(id: params[:equipment_id])

    if equipment.nil?
      return render json: { success: false, error: "Оборудование не найдено" }, status: :not_found
    end

    equipment.fids_installation = nil
    equipment.user = current_user

    if equipment.save
      render json: { success: true, message: "Оборудование успешно отвязанно" }
    else
      render json: { success: false, error: "Ошибка при отвязке оборудования" }, status: :unprocessable_entity
    end
  end

  private

  def set_installation
    @installation = FidsInstallation.find(params[:id])
  end

  def installation_params
    params.require(:fids_installation).permit(:name, :installation_type, :identifier, :terminal)
  end
end
