# frozen_string_literal: true

class HardJob
  include Sidekiq::Job

  def perform(*_args)
    user = User.first
    puts user
  end
end
