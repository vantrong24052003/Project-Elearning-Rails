# frozen_string_literal: true

class Dashboard::QuizAttemptsController < ApplicationController
  include AccountSecurity
  include NoCacheHeaders
  before_action :check_locked_account
  before_action :authenticate_user!
  before_action :set_course, only: %i[show create update destroy]
  before_action :set_quiz, only: %i[show create update destroy]
  before_action :validate_quiz_time_access, only: %i[create update]
  before_action :set_quiz_service, only: %i[show create update]
  before_action :set_quiz_attempt, only: %i[show update destroy]
  before_action :check_ownership, only: %i[show update destroy]
  before_action :set_no_cache_headers, only: [:show]

  def show
    @questions = @quiz.questions.includes(:quiz_questions)
    @results = @quiz_service.get_results(@quiz_attempt)
  end

  def create
    client_info = {
      client_ip: params[:client_ip].presence || request.remote_ip,
      device_info: request.user_agent
    }
    @quiz_attempt = @quiz_service.start_attempt(@quiz, current_user, client_info)

    redirect_to dashboard_course_quiz_quiz_attempt_path(@course, @quiz, @quiz_attempt),
                notice: 'Quiz attempt started successfully.'
  end

  def update
    return handle_quiz_submission if params[:answers].present?
    return handle_time_update if params[:time_spent].present?
    return handle_attempt_update if params[:quiz_attempt].present?

    redirect_to dashboard_course_quiz_path(@course, @quiz), alert: 'There is no data to update.'
  end

  def destroy
    @quiz_attempt.destroy
    redirect_to dashboard_course_quiz_path(@course), notice: 'Quiz attempt deleted successfully.'
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_quiz
    @quiz = @course.quizzes.find(params[:quiz_id])
  end

  def set_quiz_service
    @quiz_service = Dashboard::QuizService.new
  end

  def set_quiz_attempt
    @quiz_attempt = @quiz.quiz_attempts.find(params[:id])
  end

  def check_ownership
    return if current_user == @quiz_attempt.user

    redirect_to dashboard_course_quizzes_path(@course),
                alert: 'You are not authorized to view this quiz attempt.'
  end

  def quiz_attempt_params
    params.require(:quiz_attempt).permit(:answers, :time_spent)
  end

  def format_answers(answers_params)
    formatted_answers = {}
    answers_params.each do |question_id, selected_option|
      formatted_answers[question_id.to_s] = selected_option.to_i
    end
    formatted_answers
  end

  def handle_quiz_submission
    formatted_answers = format_answers(params[:answers])
    result = @quiz_service.submit_attempt(@quiz_attempt, formatted_answers, params[:time_spent].to_i)
    log_client_action
    redirect_to dashboard_course_quiz_quiz_attempt_path(@course, @quiz, result[:attempt]),
                notice: 'Quiz submitted successfully.'
  rescue ActionController::BadRequest => e
    redirect_to dashboard_course_quiz_path(@course, @quiz), alert: e.message
  end

  def handle_time_update
    return unless @quiz_attempt.update(time_spent: params[:time_spent].to_i, completed_at: Time.current)

    log_client_action
    redirect_to dashboard_course_quiz_quiz_attempt_path(@course, @quiz, @quiz_attempt),
                notice: 'The assignment has been updated.'
  end

  def handle_attempt_update
    quiz_attempt_params_with_completed = quiz_attempt_params.merge(completed_at: Time.current)
    return unless @quiz_attempt.update(quiz_attempt_params_with_completed)

    log_client_action
    redirect_to dashboard_course_quiz_quiz_attempt_path(@course, @quiz, @quiz_attempt),
                notice: 'The assignment has been updated.'
  end

  def log_client_action
    client_ip = params[:client_ip].presence || request.remote_ip
    @quiz_attempt.log_action({ client_ip: client_ip, device_info: request.user_agent })
  end

  def validate_quiz_time_access
    case @quiz.status
    when :upcoming
      render json: { error: 'Quiz chưa mở' }, status: :forbidden
    when :expired
      render json: { error: 'Quiz đã đóng' }, status: :forbidden
    end
  end
end
