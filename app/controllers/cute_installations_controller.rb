class CuteInstallationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_installation, only: [:show, :edit, :update, :destroy, :search_equipment, :attach_equipment, :detach_equipment]
  before_action :require_delete_permission, only: [:destroy]

  def index
    @q = CuteInstallation.ransack(params[:q])
    @q.sorts = "name asc" if @q.sorts.empty?
    @installations = @q.result(distinct: true).includes(:cute_equipments)
  end

  def show
    @equipments = @installation.cute_equipments.ordered.limit(10)
    
    # История оборудования (привязка/отвязка) для этого места установки
    @equipment_history = Audit.where(auditable_type: "CuteEquipment")
                              .where("audited_changes::text LIKE ?", "%cute_installation_id%")
                              .order(created_at: :desc)
                              .limit(100)
                              .select { |audit| 
                                changes = audit.read_attribute(:audited_changes)
                                if changes.is_a?(Hash) && changes["cute_installation_id"].is_a?(Array)
                                  old_val, new_val = changes["cute_installation_id"]
                                  old_val == @installation.id || new_val == @installation.id
                                else
                                  false
                                end
                              }
                              .first(20)
  end

  def new
    @installation = CuteInstallation.new
    
    if turbo_frame_request?
      render partial: "modal_form", locals: { installation: @installation }
    end
  end

  def create
    @installation = CuteInstallation.new(installation_params)
    @installation.user = current_user

    if @installation.save
      if turbo_frame_request?
        redirect_to cute_installations_path, notice: t("flash.created", resource: CuteInstallation.model_name.human)
      else
        redirect_to cute_installations_path, notice: t("flash.created", resource: CuteInstallation.model_name.human)
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
        redirect_to cute_installations_path, notice: t("flash.updated", resource: CuteInstallation.model_name.human)
      else
        redirect_to cute_installations_path, notice: t("flash.updated", resource: CuteInstallation.model_name.human)
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
    redirect_to cute_installations_path, notice: t("flash.deleted", resource: CuteInstallation.model_name.human)
  end

  # AJAX: Поиск оборудования по серийному номеру
  def search_equipment
    serial_number = params[:serial_number]&.strip
    
    if serial_number.blank?
      return render json: { success: false, error: "Введите серийный номер" }, status: :bad_request
    end

    equipment = CuteEquipment.find_by(serial_number: serial_number, cute_installation_id: nil)

    if equipment
      # Проверка для обычных пользователей: не более одного оборудования одного типа
      if !current_user.admin? && equipment_type_exists?(equipment.equipment_type)
        render json: {
          success: false,
          error: "К этому месту уже привязано оборудование типа \"#{equipment.human_equipment_type}\". Удалите предыдущее оборудование перед привязкой нового."
        }, status: :unprocessable_entity
      else
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
      end
    else
      existing = CuteEquipment.find_by(serial_number: serial_number)
      if existing
        render json: { success: false, error: "Оборудование уже привязано к месту установки" }, status: :not_found
      else
        render json: { success: false, error: "Оборудование с таким серийным номером не найдено" }, status: :not_found
      end
    end
  end

  # AJAX: Привязка оборудования к месту установки
  def attach_equipment
    equipment = CuteEquipment.find_by(id: params[:equipment_id], cute_installation_id: nil)

    if equipment.nil?
      return render json: { success: false, error: "Оборудование не найдено или уже привязано" }, status: :not_found
    end

    # Проверка для обычных пользователей
    if !current_user.admin? && equipment_type_exists?(equipment.equipment_type)
      return render json: { 
        success: false, 
        error: "Дублирование типов не допускается для обычных пользователей" 
      }, status: :unprocessable_entity
    end

    old_status = equipment.status
    equipment.cute_installation_id = @installation.id
    equipment.status = :active
    equipment.last_changed_by = current_user
    equipment.last_action_date = Time.current
    equipment.current_user_admin = current_user.admin?

    if equipment.save
      render json: { 
        success: true, 
        message: "Оборудование \"#{equipment.equipment_model}\" (S/N: #{equipment.serial_number}) привязано к месту установки" 
      }
    else
      render json: { success: false, error: equipment.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  # AJAX: Отвязка оборудования от места установки
  def detach_equipment
    equipment = @installation.cute_equipments.find_by(id: params[:equipment_id])

    if equipment.nil?
      return render json: { success: false, error: "Оборудование не найдено" }, status: :not_found
    end

    equipment.cute_installation_id = nil
    equipment.status = :ready_to_dispatch
    equipment.last_changed_by = current_user
    equipment.last_action_date = Time.current

    if equipment.save
      render json: { 
        success: true, 
        message: "Оборудование \"#{equipment.equipment_model}\" (S/N: #{equipment.serial_number}) отвязано от места установки" 
      }
    else
      render json: { success: false, error: equipment.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  private

  def set_installation
    @installation = CuteInstallation.find(params[:id])
  end

  def installation_params
    params.require(:cute_installation).permit(:name, :installation_type, :identifier, :terminal)
  end

  def equipment_type_exists?(equipment_type)
    @installation.cute_equipments.where(equipment_type: equipment_type).exists?
  end
end
