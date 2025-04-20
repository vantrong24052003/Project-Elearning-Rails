# frozen_string_literal: true

module Rock
  class HardJob
    include Sidekiq::Job

    def perform(*_args)
      # Do something
      puts 'Hello'
    end
  end
end
