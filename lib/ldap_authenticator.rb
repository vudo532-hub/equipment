# frozen_string_literal: true

require "net/ldap"

class LdapAuthenticator
  attr_reader :config

  def initialize(config = LDAP_CONFIG)
    @config = config
  end

  # Authenticate user against LDAP
  # Returns LDAP entry on success, nil on failure
  def authenticate(login, password)
    return nil if config.blank? || config["host"].blank?
    return nil if login.blank? || password.blank?

    ldap = build_ldap_connection

    # Search for user DN
    entry = find_user(ldap, login)
    return nil unless entry

    # Try to bind with user's password
    user_ldap = build_ldap_connection
    user_ldap.auth(entry.dn, password)

    if user_ldap.bind
      Rails.logger.info("LDAP: Successful authentication for '#{login}'")
      entry
    else
      Rails.logger.warn("LDAP: Failed bind for '#{login}': #{user_ldap.get_operation_result.message}")
      nil
    end
  rescue Net::LDAP::Error => e
    Rails.logger.error("LDAP: Connection error - #{e.message}")
    nil
  rescue StandardError => e
    Rails.logger.error("LDAP: Unexpected error - #{e.class}: #{e.message}")
    nil
  end

  # Check if LDAP is configured and available
  def available?
    config.present? && config["host"].present?
  end

  private

  def build_ldap_connection
    ldap_options = {
      host: config["host"],
      port: config["port"] || 389,
      connect_timeout: 5
    }

    if config["ssl"]
      ldap_options[:encryption] = { method: :simple_tls }
    end

    ldap = Net::LDAP.new(ldap_options)

    # Use admin credentials for searching if configured
    if config["admin_user"].present?
      ldap.auth(config["admin_user"], config["admin_password"])
    end

    ldap
  end

  def find_user(ldap, login)
    filter = Net::LDAP::Filter.eq(config["attribute"] || "sAMAccountName", login)
    results = ldap.search(
      base: config["base"],
      filter: filter,
      return_result: true,
      size: 1
    )

    if results.nil? || results.empty?
      Rails.logger.warn("LDAP: User '#{login}' not found. LDAP result: #{ldap.get_operation_result.message}")
      return nil
    end

    results.first
  end
end
