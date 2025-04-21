# frozen_string_literal: true

class User < ApplicationRecord
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable,
         :omniauthable, omniauth_providers: %i[google_oauth2 github]

  INSTRUCTOR_REQUEST_STATUSES = %w[pending approved rejected].freeze

  validates :instructor_request_status, inclusion: { in: INSTRUCTOR_REQUEST_STATUSES }, allow_nil: true

  has_many :courses
  has_many :enrollments
  has_many :enrolled_courses, through: :enrollments, source: :course

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.name = auth.info.name
      user.avatar_url = auth.info.image

      user.skip_confirmation!
      user.confirm
    end
  end

  def self.create_with_confirmation(attributes)
    user = User.new(attributes)
    user.skip_confirmation!
    user.confirm
    user.save
    user
  end

  def pending_instructor_request?
    instructor_request_status == 'pending'
  end

  def can_request_instructor?
    instructor_request_status.nil? || instructor_request_status == 'rejected'
  end

  def approve_instructor_request!(admin_user = nil)
    transaction do
      update!(
        instructor_request_status: 'approved',
        instructor_reviewed_at: Time.current
      )
      add_role(:instructor)
    end
  end

  def reject_instructor_request!(reason = nil, admin_user = nil)
    update!(
      instructor_request_status: 'rejected',
      instructor_reviewed_at: Time.current
    )
  end

  def enrolled_in?(course)
    enrolled_courses.include?(course)
  end
end
