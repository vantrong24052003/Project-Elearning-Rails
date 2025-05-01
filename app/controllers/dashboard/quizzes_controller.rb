# frozen_string_literal: true

class Dashboard::QuizzesController < Dashboard::DashboardController
  before_action :set_course
  before_action :set_quiz, only: [:show]
  before_action :check_enrollment, only: [:show]
  before_action :check_if_exam_already_taken, only: [:show]
  before_action :load_stats_data, only: [:index]

  def index
    @quizzes = @course.quizzes
    @practice_quizzes = @quizzes.where(is_exam: false)
    @exam_quizzes = @quizzes.where(is_exam: true)
  end

  def show
    @questions = @quiz.questions
    @mode = @quiz.is_exam ? 'exam' : 'practice'
  end

  def new
    @quiz = @course.quizzes.build
  end

  def create
    @quiz = @course.quizzes.build(quiz_params)

    if @quiz.save
      redirect_to dashboard_course_quiz_path(@course, @quiz), notice: 'Quiz was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @quiz.update(quiz_params)
      redirect_to dashboard_course_quiz_path(@course, @quiz), notice: 'Quiz was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @quiz.destroy
    redirect_to dashboard_course_quizzes_path(@course), notice: 'Quiz was successfully deleted.'
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_quiz
    @quiz = @course.quizzes.find(params[:id])
  end

  def check_enrollment
    return if current_user && Enrollment.exists?(user: current_user, course: @course, status: :active)

    redirect_to dashboard_course_path(@course),
                alert: 'You need to enroll in this course to take quizzes.'
  end

  def check_if_exam_already_taken
    # Nếu là bài thi và người dùng đã làm rồi thì chuyển đến trang kết quả
    return unless @quiz.is_exam? && QuizAttempt.exists?(quiz: @quiz, user: current_user)

    latest_attempt = QuizAttempt.where(quiz: @quiz, user: current_user).order(created_at: :desc).first
    redirect_to dashboard_course_quiz_attempt_path(@course, @quiz, latest_attempt),
                notice: 'You have already completed this exam. Here are your results.'
  end

  def check_if_quiz_already_submitted
    # Nếu có tham số force=true cho bài kiểm tra thường, cho phép làm lại
    return if params[:force] == 'true' && !@quiz.is_exam?

    # Chỉ áp dụng chặn submit cho bài thi, không áp dụng cho bài kiểm tra thường
    # có tham số force=true
    return unless @quiz.is_exam? && QuizAttempt.exists?(quiz: @quiz, user: current_user)

    latest_attempt = QuizAttempt.where(quiz: @quiz, user: current_user).order(created_at: :desc).first
    redirect_to dashboard_course_quiz_attempt_path(@course, @quiz, latest_attempt),
                notice: 'You have already completed this exam. Here are your results.'
  end

  def load_stats_data
    # Phân loại bài kiểm tra và bài thi
    @practice_quizzes = @course.quizzes.where(is_exam: false)
    @exam_quizzes = @course.quizzes.where(is_exam: true)

    # Lấy tất cả các lần làm bài của người dùng hiện tại
    @all_quiz_attempts = QuizAttempt.joins(:quiz)
                                    .where(user: current_user, quizzes: { course_id: @course.id })
                                    .includes(:quiz)
                                    .order(created_at: :desc)
                                    .to_a

    # Phân loại các lần làm bài kiểm tra và bài thi
    @practice_attempts = @all_quiz_attempts.select { |a| a.quiz.is_exam == false }
    @exam_attempts = @all_quiz_attempts.select { |a| a.quiz.is_exam == true }

    # Tìm lần làm bài có điểm số cao nhất cho bài kiểm tra
    @practice_best_attempt = @practice_attempts.max_by(&:score) if @practice_attempts.any?
    @practice_best_score = @practice_best_attempt ? @practice_best_attempt.score : 0

    # Tìm lần làm bài có điểm số cao nhất cho bài thi
    @exam_best_attempt = @exam_attempts.max_by(&:score) if @exam_attempts.any?
    @exam_best_score = @exam_best_attempt ? @exam_best_attempt.score : 0

    # Thống kê cho bài kiểm tra
    practice_unique_quiz_ids = @practice_attempts.map(&:quiz_id).uniq
    @completed_practice_quizzes_count = practice_unique_quiz_ids.size
    @practice_average_score = @practice_attempts.any? ? (@practice_attempts.sum(&:score).to_f / @practice_attempts.size).round(1) : 0
    @practice_completion_percentage = if @practice_quizzes.count.positive?
                                        (@completed_practice_quizzes_count.to_f / @practice_quizzes.count * 100).round
                                      else
                                        0
                                      end
    @practice_total_time_spent = @practice_attempts.sum(&:time_spent) || 0

    # Thống kê cho bài thi
    exam_unique_quiz_ids = @exam_attempts.map(&:quiz_id).uniq
    @completed_exam_quizzes_count = exam_unique_quiz_ids.size
    @exam_average_score = @exam_attempts.any? ? (@exam_attempts.sum(&:score).to_f / @exam_attempts.size).round(1) : 0
    @exam_completion_percentage = if @exam_quizzes.count.positive?
                                    (@completed_exam_quizzes_count.to_f / @exam_quizzes.count * 100).round
                                  else
                                    0
                                  end
    @exam_total_time_spent = @exam_attempts.sum(&:time_spent) || 0

    # Thống kê chung
    @recent_attempts = @all_quiz_attempts.first(10)

    unique_quiz_ids = @all_quiz_attempts.map(&:quiz_id).uniq
    @completed_quizzes_count = unique_quiz_ids.size

    @average_score = @all_quiz_attempts.any? ? (@all_quiz_attempts.sum(&:score).to_f / @all_quiz_attempts.size).round(1) : 0
    @best_score = @all_quiz_attempts.map(&:score).max || 0
    @completion_percentage = if @course.quizzes.count.positive?
                               (@completed_quizzes_count.to_f / @course.quizzes.count * 100).round
                             else
                               0
                             end

    @total_time_spent = @all_quiz_attempts.sum(&:time_spent) || 0

    # Thống kê cho bảng xếp hạng
    @total_user_attempts = QuizAttempt.joins(:quiz).where(quizzes: { course_id: @course.id }).distinct.count('user_id')

    all_course_attempts = QuizAttempt.joins(:quiz)
                                     .where(quizzes: { course_id: @course.id })
                                     .includes(:quiz, :user)
                                     .to_a

    @highest_score_attempt = all_course_attempts.max_by(&:score)
    if @highest_score_attempt
      @highest_score = @highest_score_attempt.score
      @highest_score_user = @highest_score_attempt.user
    end

    # Tạo bảng xếp hạng top 50 người dùng
    user_stats = {}
    all_course_attempts.each do |attempt|
      user_id = attempt.user_id
      user_stats[user_id] ||= {
        user: attempt.user,
        best_score: 0,
        attempts_count: 0,
        last_attempt_at: nil
      }

      user_stats[user_id][:best_score] = [user_stats[user_id][:best_score], attempt.score].max
      user_stats[user_id][:attempts_count] += 1

      if user_stats[user_id][:last_attempt_at].nil? ||
         (attempt.created_at && attempt.created_at > user_stats[user_id][:last_attempt_at])
        user_stats[user_id][:last_attempt_at] = attempt.created_at
      end
    end

    @top_users = user_stats.values.sort_by { |stat| -stat[:best_score] }.take(50)
  end

  def quiz_params
    params.require(:quiz).permit(:title, :is_exam, :time_limit)
  end
end
