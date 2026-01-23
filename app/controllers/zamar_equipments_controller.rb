class ZamarEquipmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_equipment, only: [:show, :edit, :update, :destroy]
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
