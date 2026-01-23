class FidsEquipmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_equipment, only: [:show, :edit, :update, :destroy]
  before_action :require_delete_permission, only: [:destroy]

  def index
    @q = FidsEquipment.ransack(params[:q])
    @q.sorts = "created_at desc" if @q.sorts.empty?
    @equipments = @q.result(distinct: true).includes(:fids_installation)
    @installations = FidsInstallation.ordered
  end

  def show
  end

  def new
    @equipment = FidsEquipment.new
    @equipment.fids_installation_id = params[:fids_installation_id] if params[:fids_installation_id].present?
    @installations = FidsInstallation.ordered
  end

  def create
    @equipment = FidsEquipment.new(equipment_params)
    @equipment.user = current_user
    @equipment.last_changed_by = current_user

    if @equipment.save
      redirect_to fids_equipments_path, notice: t("flash.created", resource: FidsEquipment.model_name.human)
    else
      @installations = FidsInstallation.ordered
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @installations = FidsInstallation.ordered
  end

  def update
    @equipment.last_changed_by = current_user
    if @equipment.update(equipment_params)
      redirect_to fids_equipment_path(@equipment), notice: t("flash.updated", resource: FidsEquipment.model_name.human)
    else
      @installations = FidsInstallation.ordered
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @equipment.destroy
    redirect_to fids_equipments_path, notice: t("flash.deleted", resource: FidsEquipment.model_name.human)
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
