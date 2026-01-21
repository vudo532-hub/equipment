class AuditLogsController < ApplicationController
  before_action :authenticate_user!

  def index
    @audits = Audit.includes(:user)
                   .where(user_id: current_user.id)
                   .order(created_at: :desc)
                   .limit(100)
  end
end
