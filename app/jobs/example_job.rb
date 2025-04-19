# frozen_string_literal: true

class ExampleJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Your background job logic here
    Rails.logger.info "Performing ExampleJob with arguments: #{args.inspect}"
  end
end
