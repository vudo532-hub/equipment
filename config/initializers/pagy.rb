# frozen_string_literal: true

# Pagy initializer for pagination
# See https://ddnexus.github.io/pagy/docs/extras

require 'pagy'

# Pagy 43.x uses frozen DEFAULT, pagination limit is set at runtime via pagy method call
# Default limit is 20, which is suitable for our use case
