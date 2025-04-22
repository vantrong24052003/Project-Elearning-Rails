# frozen_string_literal: true

class Video < ApplicationRecord
  belongs_to :lesson
  belongs_to :upload

  validates :title, presence: true
end
