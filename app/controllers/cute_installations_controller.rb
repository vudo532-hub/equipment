class CuteInstallationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_installation, only: [:show, :edit, :update, :destroy]
  before_action :require_delete_permission, only: [:destroy]

  def index
    @q = CuteInstallation.ransack(params[:q])
    @q.sorts = "name asc" if @q.sorts.empty?
    @installations = @q.result(distinct: true).includes(:cute_equipments)
  end

  def show
    @equipments = @installation.cute_equipments.ordered.limit(10)
  end

  def new
    @installation = CuteInstallation.new
  end

  def create
    @installation = CuteInstallation.new(installation_params)
    @installation.user = current_user

    if @installation.save
      redirect_to cute_installations_path, notice: t("flash.created", resource: CuteInstallation.model_name.human)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @installation.update(installation_params)
      redirect_to cute_installations_path, notice: t("flash.updated", resource: CuteInstallation.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @installation.destroy
    redirect_to cute_installations_path, notice: t("flash.deleted", resource: CuteInstallation.model_name.human)
  end

  private

  def set_installation
    @installation = CuteInstallation.find(params[:id])
  end

  def installation_params
    params.require(:cute_installation).permit(:name, :installation_type, :identifier, :terminal)
  end
end
