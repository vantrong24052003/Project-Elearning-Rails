# frozen_string_literal: true

class CourseCategory < ApplicationRecord
  belongs_to :course
  belongs_to :category
end
