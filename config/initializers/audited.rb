# frozen_string_literal: true

Audited.config do |config|
  # You can specify a different audit model to use.
  # config.audit_class = "CustomAudit"

  # Run audits on the given queue in an ActiveJob
  # config.audit_queue = :audits

  # Specify a custom max_audits value for all audited models
  # config.max_audits = 50
end

# Исправление сериализации для Rails 8 / Ruby 3.4
# Используем JSON вместо YAML для audited_changes
Rails.application.config.after_initialize do
  if defined?(Audited::Audit)
    Audited::Audit.class_eval do
      serialize :audited_changes, coder: JSON
    end
  end
end
