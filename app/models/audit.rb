# frozen_string_literal: true

# Custom Audit model with JSON serialization
class Audit < Audited::Audit
  serialize :audited_changes, coder: JSON
end
