# frozen_string_literal: true

class User < ApplicationRecord
  rolify

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable

  enumerize :instructor_request_status, in: %i[pending approved rejected], predicates: true, scope: true

  has_many :courses, dependent: :destroy
  has_many :enrollments, dependent: :destroy
  has_many :enrolled_courses, through: :enrollments, source: :course
  has_many :progresses, dependent: :destroy
  has_many :completed_lessons, -> { joins(:progresses).where(progresses: { status: :done }) },
           through: :progresses,
           source: :lesson
  has_many :video_progresses, dependent: :destroy
  has_many :watched_videos, through: :video_progresses, source: :video
  has_many :uploads, dependent: :destroy
end
