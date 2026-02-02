# frozen_string_literal: true

# Pagy initializer for pagination
# See https://ddnexus.github.io/pagy/docs/extras

require 'pagy/extras/overflow'

# Default configuration
Pagy::DEFAULT[:items] = 25
Pagy::DEFAULT[:overflow] = :last_page
