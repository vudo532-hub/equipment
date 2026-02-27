# frozen_string_literal: true

# Load LDAP configuration
LDAP_CONFIG = begin
  config_file = Rails.root.join("config", "ldap.yml")
  if File.exist?(config_file)
    YAML.safe_load(
      ERB.new(File.read(config_file)).result,
      permitted_classes: [],
      permitted_symbols: [],
      aliases: true
    )[Rails.env] || {}
  else
    Rails.logger.warn("LDAP config file not found at #{config_file}")
    {}
  end
rescue StandardError => e
  Rails.logger.error("Failed to load LDAP config: #{e.message}")
  {}
end
