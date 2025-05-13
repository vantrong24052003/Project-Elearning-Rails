# frozen_string_literal: true

class Dashboard::QuizAttemptsController < Dashboard::DashboardController
  before_action :set_course
  before_action :set_quiz
  before_action :set_quiz_attempt, only: %i[show edit update destroy]
  before_action :authenticate_user!

  def index
    @quiz_attempts = @quiz.quiz_attempts.where(user: current_user).order(created_at: :desc)
  end

  def show; end

  def new
    @quiz_attempt = @quiz.quiz_attempts.build
  end

  def create
    @quiz_attempt = @quiz.quiz_attempts
                         .where(user: current_user)
                         .where(completed_at: nil)
                         .order(created_at: :desc)
                         .first

    unless @quiz_attempt
      @quiz_attempt = @quiz.quiz_attempts.build
      @quiz_attempt.user = current_user
      @quiz_attempt.start_time = Time.current
      @quiz_attempt.device_info = request.user_agent
      @quiz_attempt.ip_address = request.remote_ip
    end

    correct_answers = 0
    total_questions = @quiz.questions.count

    params[:answers]&.each do |question_id, selected_option|
      question = @quiz.questions.find(question_id)
      correct_answers += 1 if question.correct_option.to_i == selected_option.to_i
    end

    @quiz_attempt.answers = params[:answers].to_json
    @quiz_attempt.score = (correct_answers.to_f / total_questions * 100).round(1)
    @quiz_attempt.completed_at = Time.current
    @quiz_attempt.time_spent = params[:time_spent].to_i

    if @quiz_attempt.save
      redirect_to dashboard_course_quiz_attempt_path(@course, @quiz, @quiz_attempt),
                  notice: 'Bài làm đã được nộp thành công.'
    else
      redirect_to dashboard_course_quiz_path(@course, @quiz), alert: 'Có lỗi xảy ra khi nộp bài.'
    end
  end

  def edit; end

  def update
    if @quiz_attempt.update(quiz_attempt_params)
      redirect_to dashboard_course_quiz_attempt_path(@course, @quiz, @quiz_attempt), notice: 'Bài làm đã được cập nhật.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @quiz_attempt.destroy
    redirect_to dashboard_course_quiz_attempts_path(@course, @quiz), notice: 'Bài làm đã được xóa.'
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_quiz
    @quiz = @course.quizzes.find(params[:quiz_id])
  end

  def set_quiz_attempt
    @quiz_attempt = @quiz.quiz_attempts.find(params[:id])
  end

  def quiz_attempt_params
    params.require(:quiz_attempt).permit(:answers, :time_spent)
  end
end
