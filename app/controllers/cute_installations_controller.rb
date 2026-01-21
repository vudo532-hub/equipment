class CuteInstallationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_installation, only: [:show, :edit, :update, :destroy]

  def index
    @q = current_user.cute_installations.ransack(params[:q])
    @q.sorts = "name asc" if @q.sorts.empty?
    @installations = @q.result(distinct: true).includes(:cute_equipments)
  end

  def show
    @equipments = @installation.cute_equipments.ordered.limit(10)
  end

  def new
    @installation = current_user.cute_installations.build
  end

  def create
    @installation = current_user.cute_installations.build(installation_params)

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
    @installation = current_user.cute_installations.find(params[:id])
  end

  def installation_params
    params.require(:cute_installation).permit(:name, :installation_type, :identifier)
  end
end
