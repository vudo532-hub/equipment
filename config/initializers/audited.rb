# frozen_string_literal: true

Audited.config do |config|
  # Use custom Audit model with JSON serialization
  config.audit_class = "Audit"

  # Run audits on the given queue in an ActiveJob
  # config.audit_queue = :audits

  # Specify a custom max_audits value for all audited models
  # config.max_audits = 50
end
