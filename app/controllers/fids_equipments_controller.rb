class FidsEquipmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_equipment, only: [:show, :edit, :update, :destroy]

  def index
    @equipments = current_user.fids_equipments
                              .includes(:fids_installation)
                              .ordered
    @equipments = @equipments.search_by_name(params[:search]) if params[:search].present?
    @equipments = @equipments.by_status(params[:status]) if params[:status].present?
    @equipments = @equipments.where(fids_installation_id: params[:installation_id]) if params[:installation_id].present?
  end

  def show
  end

  def new
    @equipment = current_user.fids_equipments.build
    @equipment.fids_installation_id = params[:fids_installation_id] if params[:fids_installation_id].present?
    @installations = current_user.fids_installations.ordered
  end

  def create
    @equipment = current_user.fids_equipments.build(equipment_params)

    if @equipment.save
      redirect_to fids_equipments_path, notice: t("flash.created", resource: FidsEquipment.model_name.human)
    else
      @installations = current_user.fids_installations.ordered
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @installations = current_user.fids_installations.ordered
  end

  def update
    if @equipment.update(equipment_params)
      redirect_to fids_equipment_path(@equipment), notice: t("flash.updated", resource: FidsEquipment.model_name.human)
    else
      @installations = current_user.fids_installations.ordered
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @equipment.destroy
    redirect_to fids_equipments_path, notice: t("flash.deleted", resource: FidsEquipment.model_name.human)
  end

  private

  def set_equipment
    @equipment = current_user.fids_equipments.find(params[:id])
  end

  def equipment_params
    params.require(:fids_equipment).permit(
      :name, :equipment_type, :equipment_model, :serial_number,
      :inventory_number, :status, :notes, :fids_installation_id
    )
  end
end
