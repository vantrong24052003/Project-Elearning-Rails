# frozen_string_literal: true

require_relative '../constants/enums'

class User < ApplicationRecord
  rolify

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable

  validates :instructor_request_status, inclusion: { in: INSTRUCTOR_REQUEST_STATUSES }, allow_nil: true

  has_many :courses
  has_many :enrollments
  has_many :enrolled_courses, through: :enrollments, source: :course

  def self.create_with_confirmation(attributes)
    user = User.new(attributes)
    user.skip_confirmation!
    user.confirm
    user.save
    user
  end
end
