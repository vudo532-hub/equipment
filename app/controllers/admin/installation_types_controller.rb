# frozen_string_literal: true

module Admin
  class InstallationTypesController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin!
    before_action :set_installation_type, only: [:edit, :update, :destroy]

    def index
      @system = params[:system] || "cute"
      @installation_types = InstallationType.where(system: @system).order(:position, :name)
    end

    def new
      @installation_type = InstallationType.new(system: params[:system] || "cute")
    end

    def create
      @installation_type = InstallationType.new(installation_type_params)

      if @installation_type.save
        redirect_to admin_installation_types_path(system: @installation_type.system),
                    notice: "Тип места установки добавлен"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @installation_type.update(installation_type_params)
        redirect_to admin_installation_types_path(system: @installation_type.system),
                    notice: "Тип места установки обновлён"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      system = @installation_type.system

      if @installation_type.can_destroy?
        @installation_type.destroy
        redirect_to admin_installation_types_path(system: system),
                    notice: "Тип места установки удалён"
      else
        redirect_to admin_installation_types_path(system: system),
                    alert: "Невозможно удалить: используется в #{@installation_type.installation_count} записях"
      end
    end

    def reorder
      params[:installation_type_ids].each_with_index do |id, index|
        InstallationType.find(id).update(position: index)
      end

      head :ok
    end

    private

    def require_admin!
      unless current_user.admin?
        redirect_to root_path, alert: "Доступ запрещён. Требуются права администратора."
      end
    end

    def set_installation_type
      @installation_type = InstallationType.find(params[:id])
    end

    def installation_type_params
      params.require(:installation_type).permit(:system, :name, :code, :active)
    end
  end
end
