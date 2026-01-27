class FidsEquipmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_equipment, only: [:show, :edit, :update, :destroy, :assign_to_installation, :unassign_from_installation, :audit_history]
  before_action :require_delete_permission, only: [:destroy]

  def index
    @q = FidsEquipment.ransack(params[:q])
    @q.sorts = "created_at desc" if @q.sorts.empty?
    @equipments = @q.result(distinct: true).includes(:fids_installation)
    @installations = FidsInstallation.ordered
    @installation_types = FidsInstallation.distinct.pluck(:installation_type).compact.sort
  end

  def show
  end

  def new
    @equipment = FidsEquipment.new
    @equipment.fids_installation_id = params[:fids_installation_id] if params[:fids_installation_id].present?
    @installations = FidsInstallation.ordered

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(
            "equipment-modal-frame",
            partial: "shared/equipment_form",
            locals: { equipment: @equipment, equipment_type: "fids", installations: @installations }
          ),
          turbo_stream.append("body", "<script>document.getElementById('equipment-modal').classList.remove('hidden'); document.body.classList.add('overflow-hidden');</script>".html_safe)
        ]
      end
    end
  end

  def create
    @equipment = FidsEquipment.new(equipment_params)
    @equipment.user = current_user
    @equipment.last_changed_by = current_user

    if @equipment.save
      respond_to do |format|
        format.html do
          redirect_to fids_equipments_path, notice: t("flash.created", resource: FidsEquipment.model_name.human)
        end
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("equipment-modal-frame", ""),
            turbo_stream.append("equipment-table-body",
              partial: "shared/equipment_row",
              locals: { equipment: @equipment, equipment_type: "fids" }
            ),
            turbo_stream.replace("flash-messages",
              partial: "shared/flash_message",
              locals: { message: t("flash.created", resource: FidsEquipment.model_name.human), type: "success" }
            )
          ]
        end
      end
    else
      @installations = FidsInstallation.ordered
      respond_to do |format|
        format.html do
          render :new, status: :unprocessable_entity
        end
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "equipment-modal-frame",
            partial: "shared/equipment_form",
            locals: { equipment: @equipment, equipment_type: "fids", installations: @installations }
          ), status: :unprocessable_entity
        end
      end
    end
  end

  def edit
    @installations = FidsInstallation.ordered

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(
            "equipment-modal-frame",
            partial: "shared/equipment_form",
            locals: { equipment: @equipment, equipment_type: "fids", installations: @installations }
          ),
          turbo_stream.append("body", "<script>document.getElementById('equipment-modal').classList.remove('hidden'); document.body.classList.add('overflow-hidden');</script>".html_safe)
        ]
      end
    end
  end

  def update
    @equipment.last_changed_by = current_user
    if @equipment.update(equipment_params)
      respond_to do |format|
        format.html do
          redirect_to fids_equipment_path(@equipment), notice: t("flash.updated", resource: FidsEquipment.model_name.human)
        end
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("equipment-modal-frame", ""),
            turbo_stream.replace("equipment-row-#{@equipment.id}",
              partial: "shared/equipment_row",
              locals: { equipment: @equipment, equipment_type: "fids" }
            ),
            turbo_stream.replace("flash-messages",
              partial: "shared/flash_message",
              locals: { message: t("flash.updated", resource: FidsEquipment.model_name.human), type: "success" }
            )
          ]
        end
      end
    else
      @installations = FidsInstallation.ordered
      respond_to do |format|
        format.html do
          render :edit, status: :unprocessable_entity
        end
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "equipment-modal-frame",
            partial: "shared/equipment_form",
            locals: { equipment: @equipment, equipment_type: "fids", installations: @installations }
          ), status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    @equipment.destroy
    redirect_to fids_equipments_path, notice: t("flash.deleted", resource: FidsEquipment.model_name.human)
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
          action_text: helpers.format_audit_action(audit, FidsEquipment),
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
    @equipment = FidsEquipment.find(params[:id])
  end

  def equipment_params
    params.require(:fids_equipment).permit(
      :name, :equipment_type, :equipment_model, :serial_number,
      :inventory_number, :status, :notes, :fids_installation_id
    )
  end
end
