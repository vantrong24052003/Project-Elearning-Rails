# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  extend Enumerize
  primary_abstract_class
end
