class CuteEquipmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_equipment, only: [:show, :edit, :update, :destroy, :audit_history]
  before_action :require_delete_permission, only: [:destroy]

  def index
    @q = CuteEquipment.ransack(params[:q])
    @q.sorts = "created_at desc" if @q.sorts.empty?
    
    equipments = @q.result(distinct: true).includes(:cute_installation)
    
    # Filter by terminal if specified
    if params[:terminal].present?
      installation_ids = CuteInstallation.where(terminal: params[:terminal]).pluck(:id)
      equipments = equipments.where(cute_installation_id: installation_ids)
    end
    
    # Filter unassigned for JSON API
    if params[:unassigned] == "true"
      equipments = equipments.unassigned
    end
    
    @equipments = equipments
    @installations = CuteInstallation.ordered
    @installation_types = CuteInstallation.distinct.pluck(:installation_type).compact.sort
    
    respond_to do |format|
      format.html
      format.json do
        render json: @equipments.map { |e|
          {
            id: e.id,
            equipment_type: e.equipment_type,
            equipment_type_text: e.equipment_type_text,
            inventory_number: e.inventory_number,
            equipment_model: e.equipment_model
          }
        }
      end
    end
  end

  def show
  end

  def new
    @equipment = CuteEquipment.new
    @equipment.cute_installation_id = params[:cute_installation_id] if params[:cute_installation_id].present?
    @installations = CuteInstallation.ordered
    @equipment_type = 'cute'

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "equipment-modal-frame",
          partial: "shared/equipment_modal_form",
          locals: { equipment: @equipment, equipment_type: @equipment_type, installations: @installations }
        )
      end
    end
  end

  def create
    @equipment = CuteEquipment.new(equipment_params)
    @equipment.user = current_user
    @equipment.last_changed_by = current_user
    @equipment.current_user_admin = current_user.admin?
    @equipment_type = 'cute'

    if @equipment.save
      respond_to do |format|
        format.html do
          redirect_to cute_equipments_path, notice: t("flash.created", resource: CuteEquipment.model_name.human)
        end
        format.turbo_stream do
          updates = [
            turbo_stream.replace("equipment-modal-frame", ""),
            turbo_stream.replace("flash-messages",
              partial: "shared/flash_message",
              locals: { message: t("flash.created", resource: CuteEquipment.model_name.human), type: "success" }
            )
          ]
          updates << turbo_stream.append("equipment-table-body",
            partial: "shared/equipment_row",
            locals: { equipment: @equipment, equipment_type: "cute" }
          ) if turbo_request_from_modal?
          render turbo_stream: updates
        end
      end
    else
      @installations = CuteInstallation.ordered
      respond_to do |format|
        format.html do
          render :new, status: :unprocessable_entity
        end
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "equipment-modal-frame",
            partial: "shared/equipment_modal_form",
            locals: { equipment: @equipment, equipment_type: @equipment_type, installations: @installations }
          ), status: :unprocessable_entity
        end
      end
    end
  end

  def edit
    @installations = CuteInstallation.ordered
    @equipment_type = 'cute'

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "equipment-modal-frame",
          partial: "shared/equipment_modal_form",
          locals: { equipment: @equipment, equipment_type: @equipment_type, installations: @installations }
        )
      end
    end
  end

  def update
    @equipment.last_changed_by = current_user
    @equipment.current_user_admin = current_user.admin?
    @equipment_type = 'cute'

    if @equipment.update(equipment_params)
      respond_to do |format|
        format.html do
          if params[:from] == 'show'
            redirect_to cute_equipment_path(@equipment), notice: t("flash.updated", resource: CuteEquipment.model_name.human)
          else
            redirect_to cute_equipments_path, notice: t("flash.updated", resource: CuteEquipment.model_name.human)
          end
        end
        format.turbo_stream do
          updates = [
            turbo_stream.replace("equipment-modal-frame", ""),
            turbo_stream.dispatch("close:modal"),
            turbo_stream.replace("flash-messages",
              partial: "shared/flash_message",
              locals: { message: t("flash.updated", resource: CuteEquipment.model_name.human), type: "success" }
            )
          ]
          updates << turbo_stream.replace("equipment-row-#{@equipment.id}",
            partial: "shared/equipment_row",
            locals: { equipment: @equipment, equipment_type: "cute" }
          ) if turbo_request_from_modal?
          render turbo_stream: updates
        end
      end
    else
      @installations = CuteInstallation.ordered
      respond_to do |format|
        format.html do
          render :edit, status: :unprocessable_entity
        end
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "equipment-modal-frame",
            partial: "shared/equipment_modal_form",
            locals: { equipment: @equipment, equipment_type: @equipment_type, installations: @installations }
          ), status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    @equipment.destroy
    redirect_to cute_equipments_path, notice: t("flash.deleted", resource: CuteEquipment.model_name.human)
  end

  def destroy
    @equipment.destroy
    redirect_to cute_equipments_path, notice: t("flash.deleted", resource: CuteEquipment.model_name.human)
  end

  # AJAX endpoint для проверки дублирования оборудования
  def check_duplicate
    equipment_type = params[:equipment_type]
    installation_id = params[:installation_id]
    exclude_id = params[:exclude_id]

    duplicate = CuteEquipment.find_duplicate(equipment_type, installation_id, exclude_id)

    if duplicate
      render json: {
        duplicate: true,
        equipment: {
          id: duplicate.id,
          inventory_number: duplicate.inventory_number,
          serial_number: duplicate.serial_number,
          status: duplicate.status_text,
          equipment_type: duplicate.equipment_type_text
        }
      }
    else
      render json: { duplicate: false }
    end
  end

  # AJAX endpoint для привязки оборудования к месту
  def assign_to_installation
    installation = CuteInstallation.find(params[:installation_id])
    
    @equipment.cute_installation = installation
    @equipment.last_changed_by = current_user
    @equipment.current_user_admin = current_user.admin?

    if @equipment.save
      render json: { success: true, message: "Оборудование успешно привязано" }
    else
      render json: { success: false, errors: @equipment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # AJAX endpoint для отвязки оборудования от места
  def unassign_from_installation
    @equipment.cute_installation = nil
    @equipment.last_changed_by = current_user

    if @equipment.save
      render json: { success: true, message: "Оборудование успешно отвязано" }
    else
      render json: { success: false, errors: @equipment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # AJAX endpoint для истории изменений
  def audit_history
    page = (params[:page] || 1).to_i
    per_page = 30
    offset = (page - 1) * per_page
    
    audits = @equipment.audits.includes(:user).order(created_at: :desc).offset(offset).limit(per_page)
    total_count = @equipment.audits.count
    has_more = (offset + per_page) < total_count
    
    render json: {
      audits: audits.map { |audit|
        {
          id: audit.id,
          action: audit.action,
          action_text: helpers.format_audit_action(audit, CuteEquipment),
          action_icon: helpers.audit_action_icon(audit.action),
          user_name: audit.user&.full_name || "Система",
          user_initials: audit.user&.initials || "?",
          created_at: helpers.format_datetime_ru(audit.created_at)
        }
      },
      has_more: has_more,
      page: page
    }
  end

  private

  def set_equipment
    @equipment = CuteEquipment.find(params[:id])
  end

  def equipment_params
    params.require(:cute_equipment).permit(
      :name, :equipment_type, :equipment_model, :serial_number,
      :inventory_number, :status, :note, :cute_installation_id
    )
  end

  def turbo_request_from_modal?
    request.headers['Turbo-Frame'] == 'equipment-modal-frame'
  end
end
