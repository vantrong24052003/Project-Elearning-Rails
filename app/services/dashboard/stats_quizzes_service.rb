# frozen_string_literal: true

class Dashboard::StatsQuizzesService
  def self.call(course:, user:)
    new(course, user).call
  end

  def initialize(course, user)
    @course = course
    @user = user
  end

  def call
    {
      practice_quizzes: @course.quizzes.practice,
      exam_quizzes: @course.quizzes.exam,
      practice_attempts: practice_attempts.to_a,
      exam_attempts: exam_attempts.to_a,
      practice_best_score: practice_attempts.maximum(:score) || 0,
      exam_best_score: exam_attempts.maximum(:score) || 0,
      completed_practice_quizzes_count: practice_attempts.distinct.count(:quiz_id),
      completed_exam_quizzes_count: exam_attempts.distinct.count(:quiz_id),
      practice_average_score: practice_attempts.average(:score)&.round(1) || 0,
      exam_average_score: exam_attempts.average(:score)&.round(1) || 0,
      practice_total_time_spent: practice_attempts.sum(:time_spent) || 0,
      exam_total_time_spent: exam_attempts.sum(:time_spent) || 0,
      total_user_attempts: QuizAttempt.for_course(@course.id).distinct.count(:user_id),
      highest_score: highest_score_data&.score || 0,
      highest_score_user: highest_score_user_data,
      top_users: top_users_data
    }
  end

  private

  def user_attempts
    @user_attempts ||= QuizAttempt.for_course(@course.id).for_user(@user.id)
  end

  def practice_attempts
    @practice_attempts ||= user_attempts.practice.includes(:quiz)
  end

  def exam_attempts
    @exam_attempts ||= user_attempts.exam.includes(:quiz)
  end

  def highest_score_data
    @highest_score_data ||= QuizAttempt.for_course(@course.id).joins(:user)
                                       .select('quiz_attempts.score, users.id as user_id, users.name as user_name')
                                       .order(score: :desc)
                                       .first
  end

  def highest_score_user_data
    return nil unless highest_score_data
    User.new(id: highest_score_data.user_id, name: highest_score_data.user_name)
  end

  def top_users_data
    @top_users_data ||= QuizAttempt.for_course(@course.id).joins(:user)
                                   .select('quiz_attempts.user_id, MAX(quiz_attempts.score) as best_score, COUNT(quiz_attempts.id) as attempts_count, MAX(quiz_attempts.created_at) as last_attempt_at, users.name as user_name')
                                   .group(:user_id, 'users.name').order('best_score DESC').limit(50)
                                   .map do |data|
      {
        user: User.new(id: data.user_id, name: data.user_name),
        best_score: data.best_score,
        attempts_count: data.attempts_count,
        last_attempt_at: data.last_attempt_at
      }
    end
  end
end
