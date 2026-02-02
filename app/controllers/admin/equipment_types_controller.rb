# frozen_string_literal: true

module Admin
  class EquipmentTypesController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin!
    before_action :set_equipment_type, only: [:edit, :update, :destroy]

    def index
      @system = params[:system] || "cute"
      @equipment_types = EquipmentType.where(system: @system).order(:position, :name)
    end

    def new
      @equipment_type = EquipmentType.new(system: params[:system] || "cute")
    end

    def create
      @equipment_type = EquipmentType.new(equipment_type_params)

      if @equipment_type.save
        redirect_to admin_equipment_types_path(system: @equipment_type.system),
                    notice: "Тип оборудования добавлен"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @equipment_type.update(equipment_type_params)
        redirect_to admin_equipment_types_path(system: @equipment_type.system),
                    notice: "Тип оборудования обновлён"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      system = @equipment_type.system

      if @equipment_type.can_destroy?
        @equipment_type.destroy
        redirect_to admin_equipment_types_path(system: system),
                    notice: "Тип оборудования удалён"
      else
        redirect_to admin_equipment_types_path(system: system),
                    alert: "Невозможно удалить: используется в #{@equipment_type.equipment_count} записях"
      end
    end

    def reorder
      params[:equipment_type_ids].each_with_index do |id, index|
        EquipmentType.find(id).update(position: index)
      end

      head :ok
    end

    private

    def require_admin!
      unless current_user.admin?
        redirect_to root_path, alert: "Доступ запрещён. Требуются права администратора."
      end
    end

    def set_equipment_type
      @equipment_type = EquipmentType.find(params[:id])
    end

    def equipment_type_params
      params.require(:equipment_type).permit(:system, :name, :code, :active)
    end
  end
end
