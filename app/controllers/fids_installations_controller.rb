class FidsInstallationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_installation, only: [:show, :edit, :update, :destroy]

  def index
    @installations = current_user.fids_installations
                                 .includes(:fids_equipments)
                                 .ordered
    @installations = @installations.search_by_name(params[:search]) if params[:search].present?
    @installations = @installations.by_type(params[:installation_type]) if params[:installation_type].present?
  end

  def show
    @equipments = @installation.fids_equipments.ordered.limit(10)
  end

  def new
    @installation = current_user.fids_installations.build
  end

  def create
    @installation = current_user.fids_installations.build(installation_params)

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
    @installation = current_user.fids_installations.find(params[:id])
  end

  def installation_params
    params.require(:fids_installation).permit(:name, :installation_type, :identifier)
  end
end
