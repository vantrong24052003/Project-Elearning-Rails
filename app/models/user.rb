# frozen_string_literal: true

require_relative '../constants/enums'

class User < ApplicationRecord
  extend Enumerize

  rolify

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable

  enumerize :instructor_request_status, in: %i[pending approved rejected], predicates: true, scope: true

  has_many :courses
  has_many :enrollments
  has_many :enrolled_courses, through: :enrollments, source: :course
end
