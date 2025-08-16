# frozen_string_literal: true

class Quiz < ApplicationRecord
  belongs_to :course
  has_many :quiz_questions
  has_many :questions, through: :quiz_questions
  has_many :quiz_attempts, dependent: :destroy

  validates :title, :time_limit, presence: true

  scope :available, lambda {
    where('start_time <= ?', Time.current).where('end_time IS NULL OR end_time >= ?', Time.current)
  }
  scope :upcoming, -> { where('start_time > ?', Time.current) }
  scope :expired, -> { where('end_time < ?', Time.current) }
  scope :practice, -> { where(is_exam: false) }
  scope :exam, -> { where(is_exam: true) }
  scope :for_course, ->(course_id) { where(course_id: course_id) }

  def exam?
    is_exam
  end

  def practice?
    !is_exam
  end

  def status
    current_time = Time.current
    if start_time.present? && current_time < start_time
      :upcoming
    elsif end_time.present? && current_time > end_time
      :expired
    else
      :available
    end
  end

  def status_label
    case status
    when :upcoming then 'Chưa mở'
    when :available then 'Đang mở'
    when :expired then 'Đã đóng'
    end
  end

  def time_limit_display
    time_limit.present? ? "Giới hạn: #{time_limit} phút" : 'Không giới hạn'
  end

  def type_label
    exam? ? 'Bài thi' : 'Bài kiểm tra'
  end
end
