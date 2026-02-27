# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # POST /resource/sign_in
  def create
    login = sign_in_params[:login]&.strip&.downcase

    # Fallback для локального администратора
    if login == "administrator"
      user = User.find_by(login: "administrator")
      if user&.valid_password?(sign_in_params[:password])
        sign_in(:user, user)
        respond_with user, location: after_sign_in_path_for(user)
        return
      else
        flash[:alert] = "Неверный логин или пароль"
        redirect_to new_user_session_path
        return
      end
    end

    # LDAP + database fallback handled by Warden strategies
    self.resource = warden.authenticate!(auth_options)
    set_flash_message!(:notice, :signed_in)
    sign_in(resource_name, resource)
    respond_with resource, location: after_sign_in_path_for(resource)
  end

  protected

  def sign_in_params
    if params[:user].present?
      params.require(:user).permit(:login, :password, :remember_me)
    else
      ActionController::Parameters.new({})
    end
  end

  def auth_options
    { scope: resource_name, recall: "#{controller_path}#new" }
  end
end
