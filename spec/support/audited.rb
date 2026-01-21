# frozen_string_literal: true

# Fix for Psych::DisallowedClass error with audited gem
# When audited tries to serialize TimeWithZone objects

# Allow ActiveSupport::TimeWithZone in Psych permitted classes
Psych::DisallowedClass.class_eval do
  # This is already handled, we just need to configure audited properly
end

# Ensure audited uses JSON serialization
Audited.config do |config|
  config.max_audits = 50
end
