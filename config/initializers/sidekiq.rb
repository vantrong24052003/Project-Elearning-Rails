# frozen_string_literal: true

Sidekiq.configure_server do |config|
  config.redis = { url: 'redis://localhost:6379/0' }

  config.average_scheduled_poll_interval = 5

  config.death_handlers << lambda { |job, ex|
    DeadJobNotifier.notify(job, ex)
  }
end
