# frozen_string_literal: true

class Dashboard::QuizzesController < Dashboard::DashboardController
  before_action :set_course
  before_action :set_quiz, only: [:show]
  before_action :check_enrollment, only: [:show]
  before_action :check_if_exam_already_taken, only: [:show]
  before_action :load_stats_data, only: [:index]
  before_action :authenticate_user!

  def index
    @quizzes = @course.quizzes
    @practice_quizzes = @quizzes
    @exam_quizzes = @quizzes.where(is_exam: true)
  end

  def show
    @questions = @quiz.questions
    @mode = @quiz.is_exam ? 'exam' : 'practice'

    if @quiz.is_exam? && QuizAttempt.where(quiz: @quiz, user: current_user).where.not(completed_at: nil).exists?
      latest_attempt = QuizAttempt.where(quiz: @quiz, user: current_user).order(created_at: :desc).first
      redirect_to dashboard_course_quiz_quiz_attempts_path(@course, @quiz, latest_attempt),
                  notice: 'You have completed this test. Here are your results.'
      return
    end

    @quiz_attempt = @quiz.quiz_attempts
                         .where(user: current_user)
                         .where(completed_at: nil)
                         .order(created_at: :desc)
                         .first

    if (params[:start] == 'true') && !@quiz_attempt
      client_ip = params[:client_ip].presence || request.remote_ip

      @quiz_attempt = @quiz.quiz_attempts.create!(
        user: current_user,
        start_time: Time.current,
        score: 0,
        time_spent: 0
      )

      @quiz_attempt.log_action('start_quiz', {
        start_time: @quiz_attempt.start_time,
        client_ip: client_ip,
        device_info: request.user_agent
      })
    end
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
    return unless @quiz.is_exam?

    if QuizAttempt.where(quiz: @quiz, user: current_user).where.not(completed_at: nil).exists?
      latest_attempt = QuizAttempt.where(quiz: @quiz,
                                         user: current_user).where.not(completed_at: nil).order(created_at: :desc).first
      redirect_to dashboard_course_quiz_quiz_attempts_path(@course, @quiz, latest_attempt),
                  notice: 'You have completed this test. Here are your results.'
      return
    end

    if !(params[:start] == 'true' || params[:force] == 'true') && QuizAttempt.where(quiz: @quiz, user: current_user,
                                                                                    completed_at: nil).exists?
      QuizAttempt.where(quiz: @quiz, user: current_user,
                        completed_at: nil).order(created_at: :desc).first
      redirect_to dashboard_course_quiz_path(@course, @quiz, start: true),
                  notice: 'You have an exam in progress. Please continue working on it.'
    end
  end

  def load_stats_data
    @practice_quizzes = @course.quizzes.where(is_exam: false)
    @exam_quizzes = @course.quizzes.where(is_exam: true)

    @all_quiz_attempts = QuizAttempt.joins(:quiz)
                                    .where(user: current_user, quizzes: { course_id: @course.id })
                                    .includes(:quiz)
                                    .order(created_at: :desc)
                                    .to_a

    @practice_attempts = @all_quiz_attempts.select { |a| a.quiz.is_exam == false }
    @exam_attempts = @all_quiz_attempts.select { |a| a.quiz.is_exam == true }

    @practice_best_attempt = @practice_attempts.max_by(&:score) if @practice_attempts.any?
    @practice_best_score = @practice_best_attempt ? @practice_best_attempt.score : 0

    @exam_best_attempt = @exam_attempts.max_by(&:score) if @exam_attempts.any?
    @exam_best_score = @exam_best_attempt ? @exam_best_attempt.score : 0

    practice_unique_quiz_ids = @practice_attempts.map(&:quiz_id).uniq
    @completed_practice_quizzes_count = practice_unique_quiz_ids.size
    @practice_average_score = @practice_attempts.any? ? (@practice_attempts.sum(&:score).to_f / @practice_attempts.size).round(1) : 0
    @practice_completion_percentage = if @practice_quizzes.count.positive?
                                        (@completed_practice_quizzes_count.to_f / @practice_quizzes.count * 100).round
                                      else
                                        0
                                      end
    @practice_total_time_spent = @practice_attempts.sum(&:time_spent) || 0

    exam_unique_quiz_ids = @exam_attempts.map(&:quiz_id).uniq
    @completed_exam_quizzes_count = exam_unique_quiz_ids.size
    @exam_average_score = @exam_attempts.any? ? (@exam_attempts.sum(&:score).to_f / @exam_attempts.size).round(1) : 0
    @exam_completion_percentage = if @exam_quizzes.count.positive?
                                    (@completed_exam_quizzes_count.to_f / @exam_quizzes.count * 100).round
                                  else
                                    0
                                  end
    @exam_total_time_spent = @exam_attempts.sum(&:time_spent) || 0

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

    @total_user_attempts = QuizAttempt.joins(:quiz).where(quizzes: { course_id: @course.id }).distinct.count('user_id')

    highest_score_attempt = QuizAttempt.joins(:quiz, :user)
                                       .where(quizzes: { course_id: @course.id })
                                       .order(score: :desc)
                                       .select('quiz_attempts.*, users.id as user_id, users.name as user_name')
                                       .first

    if highest_score_attempt
      @highest_score = highest_score_attempt.score
      @highest_score_user = highest_score_attempt.user
    end

    top_users_data = QuizAttempt.joins(:quiz, :user)
                                .where(quizzes: { course_id: @course.id })
                                .select('quiz_attempts.user_id, MAX(quiz_attempts.score) as best_score, COUNT(quiz_attempts.id) as attempts_count, MAX(quiz_attempts.created_at) as last_attempt_at, users.name as user_name')
                                .group('quiz_attempts.user_id, users.name')
                                .order('best_score DESC')
                                .limit(50)

    @top_users = top_users_data.map do |data|
      {
        user: User.new(id: data.user_id, name: data.user_name),
        best_score: data.best_score,
        attempts_count: data.attempts_count,
        last_attempt_at: data.last_attempt_at
      }
    end
  end

  def quiz_params
    params.require(:quiz).permit(:title, :is_exam, :time_limit)
  end
end
