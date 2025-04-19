# frozen_string_literal: true

class Video < ApplicationRecord
  # Associations
  belongs_to :lesson
  belongs_to :upload

  # Validations
  validates :title, presence: true
end
