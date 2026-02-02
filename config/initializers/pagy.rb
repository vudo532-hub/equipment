# frozen_string_literal: true

# Pagy initializer for pagination
# See https://ddnexus.github.io/pagy/docs/extras

require 'pagy'

# В pagy 43.x настройки задаются при вызове pagy(), а не через DEFAULT
# Пример: pagy(@collection, limit: 25)
