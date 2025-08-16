# frozen_string_literal: true

class Dashboard::QuizzesController < ApplicationController
  include AccountSecurity
  include NoCacheHeaders
  before_action :check_locked_account
  before_action :authenticate_user!
  before_action :set_course, only: %i[index show]
  before_action :check_enrollment, only: [:show]
  before_action :set_no_cache_headers, only: [:show]

  def index
    @available_quizzes = @course.quizzes.available.order(created_at: :desc).page(params[:page]).per(10)
    @upcoming_quizzes = @course.quizzes.upcoming.order(created_at: :desc)
    @expired_quizzes = @course.quizzes.expired.order(created_at: :desc)
    @stats = Dashboard::StatsQuizzesService.call(course: @course, user: current_user)
  end

  def show
    @quiz = Quiz.includes(:questions, :course).find(params[:id])
    @questions = @quiz.questions
    @mode = @quiz.exam? ? 'exam' : 'practice'

    service = Dashboard::QuizService.new

    if @quiz.exam? && service.already_completed?(@quiz, current_user)
      completed = service.latest_completed_attempt(@quiz, current_user)
      redirect_to dashboard_course_quiz_quiz_attempt_path(@course, @quiz, completed),
                  notice: 'You have completed this exam.'
      return
    end

    @quiz_attempt = service.current_attempt(@quiz, current_user)
    if params[:start] == 'true' && @quiz_attempt.nil?
      client_info = {
        client_ip: params[:client_ip].presence || request.remote_ip,
        device_info: request.user_agent
      }
      @quiz_attempt = service.start_attempt(@quiz, current_user, client_info)
    end
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def check_enrollment
    return if current_user.has_role?(:admin)
    return if current_user == @course.user
    return if current_user && Enrollment.exists?(user: current_user, course: @course, status: :active)

    redirect_to dashboard_course_path(@course),
                alert: 'You need to enroll in this course to take quizzes.'
  end
end
