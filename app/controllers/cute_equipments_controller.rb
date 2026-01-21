class CuteEquipmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_equipment, only: [:show, :edit, :update, :destroy]

  def index
    @q = current_user.cute_equipments.ransack(params[:q])
    @q.sorts = "created_at desc" if @q.sorts.empty?
    @equipments = @q.result(distinct: true).includes(:cute_installation)
    @installations = current_user.cute_installations.ordered
  end

  def show
  end

  def new
    @equipment = current_user.cute_equipments.build
    @equipment.cute_installation_id = params[:cute_installation_id] if params[:cute_installation_id].present?
    @installations = current_user.cute_installations.ordered
  end

  def create
    @equipment = current_user.cute_equipments.build(equipment_params)

    if @equipment.save
      redirect_to cute_equipments_path, notice: t("flash.created", resource: CuteEquipment.model_name.human)
    else
      @installations = current_user.cute_installations.ordered
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @installations = current_user.cute_installations.ordered
  end

  def update
    if @equipment.update(equipment_params)
      redirect_to cute_equipment_path(@equipment), notice: t("flash.updated", resource: CuteEquipment.model_name.human)
    else
      @installations = current_user.cute_installations.ordered
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @equipment.destroy
    redirect_to cute_equipments_path, notice: t("flash.deleted", resource: CuteEquipment.model_name.human)
  end

  private

  def set_equipment
    @equipment = current_user.cute_equipments.find(params[:id])
  end

  def equipment_params
    params.require(:cute_equipment).permit(
      :name, :equipment_type, :equipment_model, :serial_number,
      :inventory_number, :status, :notes, :cute_installation_id
    )
  end
end
