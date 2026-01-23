class CuteEquipmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_equipment, only: [:show, :edit, :update, :destroy]
  before_action :require_delete_permission, only: [:destroy]

  def index
    @q = CuteEquipment.ransack(params[:q])
    @q.sorts = "created_at desc" if @q.sorts.empty?
    @equipments = @q.result(distinct: true).includes(:cute_installation)
    @installations = CuteInstallation.ordered
  end

  def show
  end

  def new
    @equipment = CuteEquipment.new
    @equipment.cute_installation_id = params[:cute_installation_id] if params[:cute_installation_id].present?
    @installations = CuteInstallation.ordered
  end

  def create
    @equipment = CuteEquipment.new(equipment_params)
    @equipment.user = current_user
    @equipment.last_changed_by = current_user

    if @equipment.save
      redirect_to cute_equipments_path, notice: t("flash.created", resource: CuteEquipment.model_name.human)
    else
      @installations = CuteInstallation.ordered
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @installations = CuteInstallation.ordered
  end

  def update
    @equipment.last_changed_by = current_user
    if @equipment.update(equipment_params)
      redirect_to cute_equipment_path(@equipment), notice: t("flash.updated", resource: CuteEquipment.model_name.human)
    else
      @installations = CuteInstallation.ordered
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @equipment.destroy
    redirect_to cute_equipments_path, notice: t("flash.deleted", resource: CuteEquipment.model_name.human)
  end

  private

  def set_equipment
    @equipment = CuteEquipment.find(params[:id])
  end

  def equipment_params
    params.require(:cute_equipment).permit(
      :name, :equipment_type, :equipment_model, :serial_number,
      :inventory_number, :status, :notes, :cute_installation_id
    )
  end
end
