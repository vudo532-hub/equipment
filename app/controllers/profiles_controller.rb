# frozen_string_literal: true

class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if password_update?
      update_password
    else
      update_profile
    end
  end

  private

  def password_update?
    params[:user][:current_password].present? || 
    params[:user][:password].present? || 
    params[:user][:password_confirmation].present?
  end

  def update_password
    if @user.update_with_password(password_params)
      bypass_sign_in(@user)
      redirect_to profile_path, notice: 'Пароль успешно изменён'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def update_profile
    if @user.update(profile_params)
      redirect_to profile_path, notice: 'Профиль успешно обновлён'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def profile_params
    params.require(:user).permit(:first_name, :last_name)
  end

  def password_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end
end
