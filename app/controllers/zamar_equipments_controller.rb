class ZamarEquipmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_equipment, only: [:show, :edit, :update, :destroy, :audit_history]
  before_action :require_delete_permission, only: [:destroy]

  def index
    @q = ZamarEquipment.ransack(params[:q])
    @q.sorts = "created_at desc" if @q.sorts.empty?
    @equipments = @q.result(distinct: true).includes(:zamar_installation)
    @installations = ZamarInstallation.ordered
  end

  def show
  end

  def new
    @equipment = ZamarEquipment.new
    @equipment.zamar_installation_id = params[:zamar_installation_id] if params[:zamar_installation_id].present?
    @installations = ZamarInstallation.ordered
  end

  def create
    @equipment = ZamarEquipment.new(equipment_params)
    @equipment.user = current_user
    @equipment.last_changed_by = current_user

    if @equipment.save
      redirect_to zamar_equipments_path, notice: t("flash.created", resource: ZamarEquipment.model_name.human)
    else
      @installations = ZamarInstallation.ordered
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @installations = ZamarInstallation.ordered
  end

  def update
    @equipment.last_changed_by = current_user
    if @equipment.update(equipment_params)
      redirect_to zamar_equipment_path(@equipment), notice: t("flash.updated", resource: ZamarEquipment.model_name.human)
    else
      @installations = ZamarInstallation.ordered
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @equipment.destroy
    redirect_to zamar_equipments_path, notice: t("flash.deleted", resource: ZamarEquipment.model_name.human)
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
          action_text: helpers.format_audit_action(audit, ZamarEquipment),
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
    @equipment = ZamarEquipment.find(params[:id])
  end

  def equipment_params
    params.require(:zamar_equipment).permit(
      :equipment_type, :equipment_model, :serial_number,
      :inventory_number, :status, :note, :zamar_installation_id
    )
  end
end
