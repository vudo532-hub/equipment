# frozen_string_literal: true

# Performance optimizations initializer

# === PostgreSQL: Statement timeout for safety ===
# Prevent runaway queries from locking the database
if Rails.env.production?
  ActiveSupport.on_load(:active_record) do
    ActiveRecord::Base.connection_pool.disconnect!
    ActiveRecord::Base.establish_connection(
      ActiveRecord::Base.connection_db_config.configuration_hash.merge(
        variables: {
          statement_timeout: "30s",  # Kill queries after 30 seconds
          lock_timeout: "10s"        # Kill lock waits after 10 seconds
        }
      )
    )
  end
end

# === Pagy: Efficient counting ===
# Already configured in config/initializers/pagy.rb

# === Logging: Reduce log noise in production ===
if Rails.env.production?
  # Silence asset requests
  Rails.application.config.assets.quiet = true rescue nil
end
