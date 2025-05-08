# frozen_string_literal: true

class Dashboard::QuizAttemptsController < Dashboard::DashboardController
  before_action :set_course
  before_action :set_quiz, only: [:create, :show]
  before_action :set_attempt, only: [:show]
  before_action :check_enrollment, only: [:create]
  before_action :check_if_exam_already_attempted, only: [:create], if: -> { @quiz.is_exam? }

  def create
    @attempt = QuizAttempt.new(
      quiz: @quiz,
      user: current_user,
      score: calculate_score,
      answers: params[:answers] || {},
      time_spent: params[:time_spent]
    )

    if @attempt.save
      # Thêm header để yêu cầu client xóa dữ liệu làm bài
      response.headers['X-Clear-Quiz-Storage'] = "quiz_#{@quiz.id}"

      # Nếu là bài thi, thêm header để đánh dấu
      response.headers['X-Quiz-Is-Exam'] = @quiz.is_exam?.to_s

      # Đánh dấu là đã nộp bài
      response.headers['X-Quiz-Submitted'] = 'true'

      redirect_to dashboard_course_quiz_attempt_path(@course, @quiz, @attempt), notice: 'Bài làm đã được ghi nhận.'
    else
      redirect_to dashboard_course_quiz_path(@course, @quiz), alert: 'Lỗi khi ghi nhận bài làm.'
    end
  end

  def show
    @questions = @quiz.questions
    @answers = @attempt.answers || {}
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
    unless current_user && Enrollment.exists?(user: current_user, course: @course, status: :active)
      redirect_to dashboard_course_path(@course), alert: 'Bạn cần đăng ký khóa học để làm bài kiểm tra.'
    end
  end

  def check_if_exam_already_attempted
    if QuizAttempt.exists?(quiz: @quiz, user: current_user)
      redirect_to dashboard_course_quizzes_path(@course), alert: 'Bài thi này đã được nộp. Bài thi chỉ được làm một lần duy nhất.'
    end
  end

  def calculate_score
    return 0 if !params[:answers] || params[:answers].empty?

    correct_count = 0
    params[:answers].each do |question_id, answer|
      question = Question.find_by(id: question_id)
      next unless question

      correct_count += 1 if answer.to_i == question.correct_option
    end

    questions_count = @quiz.questions.count
    return 0 if questions_count == 0

    (correct_count.to_f / questions_count * 100).round
  end
end
