# frozen_string_literal: true

class Manage::QuizAttemptsController < Manage::BaseController
  before_action :set_quiz, only: [:index]
  before_action :set_quiz_attempt, only: [:show]

  def index
    @quiz_attempts = if @quiz
                       @quiz.quiz_attempts
                     else
                       QuizAttempt.all
                     end

    @quiz_attempts = @quiz_attempts.includes(:user, :quiz)

    if params[:search].present?
      @quiz_attempts = @quiz_attempts.joins(:user).where('users.name ILIKE ? OR users.email ILIKE ?',
                                                         "%#{params[:search]}%", "%#{params[:search]}%")
    end

    case params[:cheating_score]
    when 'high'
      @quiz_attempts = @quiz_attempts.where('tab_switch_count + copy_paste_count + screenshot_count + devtools_open_count + right_click_count + other_unusual_actions + (device_count - 1) > 15')
    when 'medium'
      @quiz_attempts = @quiz_attempts.where('tab_switch_count + copy_paste_count + screenshot_count + devtools_open_count + right_click_count + other_unusual_actions + (device_count - 1) > 8')
    when 'low'
      @quiz_attempts = @quiz_attempts.where('tab_switch_count + copy_paste_count + screenshot_count + devtools_open_count + right_click_count + other_unusual_actions + (device_count - 1) <= 8')
    end

    case params[:score_range]
    when 'excellent'
      @quiz_attempts = @quiz_attempts.where('score >= 80')
    when 'good'
      @quiz_attempts = @quiz_attempts.where('score >= 50')
    when 'poor'
      @quiz_attempts = @quiz_attempts.where('score < 50')
    end

    per_page = params[:per_page].to_i.positive? ? params[:per_page].to_i : 10
    @quiz_attempts = @quiz_attempts.order(created_at: :desc).page(params[:page]).per(per_page)
  end

  def show
    @log_entries = @quiz_attempt.log_actions || []

    @ip_list = @log_entries.map { |entry| entry['client_ip'] }.compact.uniq
    @device_list = @log_entries.map { |entry| entry['device_info'] }.compact.uniq

    start_log = @log_entries.first || {}
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

  def set_quiz
    @quiz = Quiz.find(params[:quiz_id]) if params[:quiz_id].present?
  end

  def set_quiz_attempt
    @quiz_attempt = QuizAttempt.find(params[:id])
  end
end
