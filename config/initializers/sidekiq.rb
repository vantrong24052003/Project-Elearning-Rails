# frozen_string_literal: true

# config/initializers/sidekiq.rb
Sidekiq.configure_server do |config|
  config.redis = { url: 'redis://localhost:6379/0' }

  # Cấu hình retry
  config.average_scheduled_poll_interval = 5
  # config.max_retries = 10

  # Dead job configuration
  config.death_handlers << lambda { |job, ex|
    DeadJobNotifier.notify(job, ex)
  }
end
