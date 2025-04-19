class HardJob
  include Sidekiq::Job

  def perform(*args)
    user = User.first
    puts user
  end
end
