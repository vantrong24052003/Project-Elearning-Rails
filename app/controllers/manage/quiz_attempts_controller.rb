# frozen_string_literal: true

class Manage::QuizAttemptsController < Manage::BaseController
  before_action :set_quiz_attempt, only: %i[show]
  before_action :set_quiz, only: %i[index]

  def dashboard
    @courses_with_quizzes = Course.includes(:quizzes).where(quizzes: { id: QuizAttempt.select(:quiz_id).distinct })
                                  .order(created_at: :desc).page(params[:page]).per(10)
  end

  def index
    @quiz_attempts = if @quiz
                       @quiz.quiz_attempts.includes(:user).order(created_at: :desc).page(params[:page]).per(20)
                     else
                       QuizAttempt.includes(:user, :quiz).order(created_at: :desc).page(params[:page]).per(20)
                     end
  end

  def show
    @quiz_attempt = QuizAttempt.find(params[:id])
    @log_entries = @quiz_attempt.log_actions || []

    @ip_list = @log_entries.map { |entry| entry['client_ip'] }.compact.uniq
    @device_list = @log_entries.map { |entry| entry['device_info'] }.compact.uniq

    start_log = @log_entries.find { |entry| entry['action'] == 'start_quiz' } || {}
    @start_ip = start_log['client_ip'] || 'Không xác định'
    @start_device_info = start_log['device_info'] || 'Không xác định'

    cheating_logs = @log_entries.select do |entry|
      %w[tab_switch window_blur copy paste cut screenshot
         right_click devtools_open devtools_key].include?(entry['action'])
    end

    @cheating_stats = {
      tab_switches: cheating_logs.count { |entry| %w[tab_switch window_blur].include?(entry['action']) },
      copy_paste: cheating_logs.count { |entry| %w[copy paste cut].include?(entry['action']) },
      screenshots: cheating_logs.count { |entry| entry['action'] == 'screenshot' },
      right_clicks: cheating_logs.count { |entry| entry['action'] == 'right_click' },
      devtools: cheating_logs.count { |entry| %w[devtools_open devtools_key].include?(entry['action']) },
      other: cheating_logs.count do |entry|
        !%w[tab_switch window_blur copy paste cut
            screenshot right_click devtools_open
            devtools_key].include?(entry['action'])
      end
    }
  end

  private

  def set_quiz_attempt
    @quiz_attempt = QuizAttempt.includes(:user, :quiz).find(params[:id])
  end

  def set_quiz
    @quiz = Quiz.find(params[:quiz_id]) if params[:quiz_id].present?
  end
end
