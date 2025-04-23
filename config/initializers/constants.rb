# frozen_string_literal: true

# Load all constants from app/constants directory
Dir[Rails.root.join('app', 'constants', '*.rb')].sort.each { |file| require file }
