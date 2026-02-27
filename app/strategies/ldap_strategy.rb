# frozen_string_literal: true

require "net/ldap"
require_relative "../../lib/ldap_authenticator"

class LdapStrategy < Devise::Strategies::Authenticatable
  def valid?
    login.present? && password.present? && login != "administrator"
  end

  def authenticate!
    authenticator = LdapAuthenticator.new

    unless authenticator.available?
      Rails.logger.info("LDAP: Not configured, skipping LDAP authentication")
      pass
      return
    end

    entry = authenticator.authenticate(login, password)

    if entry
      user = User.find_or_create_from_ldap(login, entry)
      if user&.persisted?
        success!(user)
      else
        fail!("Ошибка создания пользователя")
      end
    else
      fail!("Неверный логин или пароль")
    end
  end

  private

  def login
    params.dig("user", "login")&.strip&.downcase
  end

  def password
    params.dig("user", "password")
  end
end

Warden::Strategies.add(:ldap_authenticatable, LdapStrategy)
