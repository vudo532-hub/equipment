class FidsInstallationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_installation, only: [:show, :edit, :update, :destroy]
  before_action :require_delete_permission, only: [:destroy]

  def index
    @q = FidsInstallation.ransack(params[:q])
    @q.sorts = "name asc" if @q.sorts.empty?
    @installations = @q.result(distinct: true).includes(:fids_equipments)
  end

  def show
    @equipments = @installation.fids_equipments.ordered.limit(10)
  end

  def new
    @installation = FidsInstallation.new
  end

  def create
    @installation = FidsInstallation.new(installation_params)
    @installation.user = current_user

    if @installation.save
      redirect_to fids_installations_path, notice: t("flash.created", resource: FidsInstallation.model_name.human)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @installation.update(installation_params)
      redirect_to fids_installations_path, notice: t("flash.updated", resource: FidsInstallation.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @installation.destroy
    redirect_to fids_installations_path, notice: t("flash.deleted", resource: FidsInstallation.model_name.human)
  end

  private

  def set_installation
    @installation = FidsInstallation.find(params[:id])
  end

  def installation_params
    params.require(:fids_installation).permit(:name, :installation_type, :identifier, :terminal)
  end
end
