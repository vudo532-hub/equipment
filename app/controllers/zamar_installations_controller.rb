class ZamarInstallationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_installation, only: [:show, :edit, :update, :destroy]
  before_action :require_delete_permission, only: [:destroy]

  def index
    @q = ZamarInstallation.ransack(params[:q])
    @q.sorts = "name asc" if @q.sorts.empty?
    @installations = @q.result(distinct: true).includes(:zamar_equipments)
  end

  def show
    @equipments = @installation.zamar_equipments.ordered.limit(10)
  end

  def new
    @installation = ZamarInstallation.new
  end

  def create
    @installation = ZamarInstallation.new(installation_params)
    @installation.user = current_user

    if @installation.save
      redirect_to zamar_installations_path, notice: t("flash.created", resource: ZamarInstallation.model_name.human)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @installation.update(installation_params)
      redirect_to zamar_installations_path, notice: t("flash.updated", resource: ZamarInstallation.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @installation.destroy
    redirect_to zamar_installations_path, notice: t("flash.deleted", resource: ZamarInstallation.model_name.human)
  end

  private

  def set_installation
    @installation = ZamarInstallation.find(params[:id])
  end

  def installation_params
    params.require(:zamar_installation).permit(:name, :installation_type, :identifier, :terminal)
  end
end
