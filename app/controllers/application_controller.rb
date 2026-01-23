class ApplicationController < ActionController::Base
  include Pagy::Method

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  protected

  # Check if current user can delete records
  def can_delete?
    current_user&.manager? || current_user&.admin?
  end
  helper_method :can_delete?

  # Require delete permission
  def require_delete_permission
    unless can_delete?
      respond_to do |format|
        format.html { redirect_back fallback_location: root_path, alert: "Удаление недоступно для вашей роли (#{current_user.role_name})" }
        format.turbo_stream { redirect_back fallback_location: root_path, alert: "Удаление недоступно для вашей роли (#{current_user.role_name})" }
      end
    end
  end
end
