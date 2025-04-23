# Load all constants from app/constants directory
Dir[Rails.root.join('app', 'constants', '*.rb')].each { |file| require file }
