# frozen_string_literal: true

class Dashboard::AttemptsController < Dashboard::DashboardController
  before_action :set_course
  before_action :set_quiz
  before_action :set_attempt, only: %i[show edit update destroy]
  before_action :check_enrollment, only: %i[index show new create]

  def index
    @attempts = QuizAttempt.where(quiz: @quiz, user: current_user)
                           .order(created_at: :desc)
  end

  def show
    @questions = @quiz.questions
  end

  def new
    @attempt = QuizAttempt.new
    @questions = @quiz.questions
  end

  def create
    answers = params[:answers] || {}
    time_spent = params[:time_spent].to_i

    correct_count = 0
    @quiz.questions.each do |question|
      user_answer = answers[question.id.to_s].to_i
      correct_count += 1 if user_answer == question.correct_option
    end
    score = @quiz.questions.count.positive? ? (correct_count.to_f / @quiz.questions.count * 100).round : 0

    @attempt = QuizAttempt.new(
      quiz: @quiz,
      user: current_user,
      score: score,
      time_spent: time_spent,
      answers: answers
    )

    if @attempt.save
      redirect_to dashboard_course_quiz_attempt_path(@course, @quiz, @attempt),
                  notice: 'Bài làm của bạn đã được lưu thành công.'
    else
      @questions = @quiz.questions
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    redirect_to dashboard_course_quiz_attempt_path(@course, @quiz, @attempt)
  end

  def update
    redirect_to dashboard_course_quiz_attempt_path(@course, @quiz, @attempt)
  end

  def destroy
    @attempt.destroy
    redirect_to dashboard_course_quiz_attempts_path(@course, @quiz),
                notice: 'Lần làm bài đã được xóa.'
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_quiz
    @quiz = @course.quizzes.find(params[:quiz_id])
  end

  def set_attempt
    @attempt = QuizAttempt.find(params[:id])
  end

  def check_enrollment
    return if current_user.enrollments.active.exists?(course: @course)

    redirect_to dashboard_course_path(@course),
                alert: 'Bạn cần đăng ký khóa học này để làm bài kiểm tra'
  end

  def quiz_attempt_params
    params.require(:quiz_attempt).permit(:score, :time_spent, answers: {})
  end
end
