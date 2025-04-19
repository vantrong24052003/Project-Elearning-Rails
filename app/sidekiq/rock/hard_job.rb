class Rock::HardJob
  include Sidekiq::Job

  def perform(*args)
    # Do something
    puts 'Hello'
  end
end
