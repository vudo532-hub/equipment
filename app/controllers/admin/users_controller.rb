# frozen_string_literal: true

module Admin
  class UsersController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin!
    before_action :set_user, only: [:edit, :update]

    def index
      @pagy, @users = pagy(User.order(:last_name, :first_name), limit: 20)
    end

    def edit
    end

    def update
      if @user.update(user_params)
        redirect_to admin_users_path, notice: "Роль пользователя #{@user.full_name} обновлена"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def require_admin!
      unless current_user.admin?
        redirect_to root_path, alert: 'Доступ запрещён. Требуются права администратора.'
      end
    end

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:role)
    end
  end
end
