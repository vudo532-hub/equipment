class AuditLogsController < ApplicationController
  before_action :authenticate_user!

  def index
    base_scope = if current_user.admin?
                   Audit.includes(:user)
                 else
                   Audit.includes(:user).where(user_id: current_user.id)
                 end

    # Фильтрация по системе
    if params[:system].present?
      auditable_types = case params[:system]
                        when "cute"
                          %w[CuteEquipment CuteInstallation]
                        when "fids"
                          %w[FidsEquipment FidsInstallation]
                        when "zamar"
                          %w[ZamarEquipment ZamarInstallation]
                        else
                          []
                        end
      base_scope = base_scope.where(auditable_type: auditable_types) if auditable_types.any?
    end

    # Фильтрация по действию
    if params[:action_type].present?
      base_scope = base_scope.where(action: params[:action_type])
    end

    @pagy, @audits = pagy(base_scope.order(created_at: :desc), limit: 50)
  end

  def show
    @audit = Audit.find(params[:id])
  end
end
