require "active_support/core_ext/integer/time"

# Containerized development environment ("dev"): runs the Docker image with an
# embedded PostgreSQL (see the `dev` stage in the Dockerfile). Unlike the
# standard "development" env it has no gem group, so the image's production
# bundle (built with BUNDLE_WITHOUT=development) boots it as-is.
# This environment is never deployed.
Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Make code changes take effect immediately without server restart.
  config.enable_reloading = true

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable server timing.
  config.server_timing = true

  # Disable Action Controller caching and keep the cache in memory; the
  # Solid Cache/Cable databases are not used in this environment.
  config.action_controller.perform_caching = false
  config.cache_store = :memory_store

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Make template changes take effect immediately.
  config.action_mailer.perform_caching = false

  # Set localhost to be used by links generated in mailer templates.
  config.action_mailer.default_url_options = { host: "localhost", port: 3000 }

  # Log to STDOUT so `docker logs` captures everything.
  config.logger = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Append comments with runtime information tags to SQL queries in logs.
  config.active_record.query_log_tags_enabled = true

  # Highlight code that enqueued background job in logs.
  config.active_job.verbose_enqueue_logs = true

  # Highlight code that triggered redirect in logs.
  config.action_dispatch.verbose_redirect_logs = true

  # Raise error when a before_action's only/except options reference missing actions.
  config.action_controller.raise_on_missing_callback_actions = true

  # Rails auto-generates a secret_key_base only for the literal "development"
  # and "test" environments, so this custom env must provide its own. A fixed
  # insecure value is fine here (never deployed) and keeps issued JWTs valid
  # across container restarts.
  config.secret_key_base = "dev-env-insecure-static-secret-key-base"
end
