# frozen_string_literal: true

class Dashboard::QuizStatusesController < ApplicationController
  include AccountSecurity
  before_action :check_locked_account
  before_action :authenticate_user!
  before_action :set_course, only: %i[index update]
  before_action :set_quiz_attempt, only: [:update]

  def index
    @quiz_attempts = QuizAttempt.joins(:quiz)
                                .where(quizzes: { course_id: @course.id }, user: current_user)
                                .select(:id, :quiz_id, :completed_at)
    render json: @quiz_attempts
  end

  def update
    return handle_cheating_action(should_log: true) if params[:action_type].present?
    return handle_behavior_counts(should_log: true) if params[:behavior_counts].present?
    return handle_state_update(should_log: true) if params[:state_data].present?
    return handle_attempt_data(should_log: true) if params[:quiz_attempt].present?

    render json: { error: 'No data' }, status: :unprocessable_entity
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_quiz_attempt
    quiz_id = params[:quiz_id]
    attempt_id = params[:id]
    @quiz = @course.quizzes.find(quiz_id) if quiz_id.present?
    @quiz_attempt = QuizAttempt.find(attempt_id)
  end

  def log_cheating_behavior(action_type = nil)
    return unless @quiz_attempt.quiz.exam?

    case action_type
    when 'tab_switch', 'window_blur', 'alt_tab'
      @quiz_attempt.increment!(:tab_switch_count)
    when 'copy', 'paste', 'cut'
      @quiz_attempt.increment!(:copy_paste_count)
    when 'screenshot'
      @quiz_attempt.increment!(:screenshot_count)
    when 'right_click'
      @quiz_attempt.increment!(:right_click_count)
    when 'devtools_open', 'devtools_key'
      @quiz_attempt.increment!(:devtools_open_count)
    when 'drag_attempt', 'drop_attempt', 'window_resize'
      @quiz_attempt.increment!(:other_unusual_actions)
    end
  end

  def update_behaviors(behavior_counts)
    return unless @quiz_attempt.quiz.exam?

    if behavior_counts[:tab_switch_count].present? && behavior_counts[:tab_switch_count].to_i > @quiz_attempt.tab_switch_count.to_i
      @quiz_attempt.update(tab_switch_count: behavior_counts[:tab_switch_count])
    end

    if behavior_counts[:copy_paste_count].present? && behavior_counts[:copy_paste_count].to_i > @quiz_attempt.copy_paste_count.to_i
      @quiz_attempt.update(copy_paste_count: behavior_counts[:copy_paste_count])
    end

    if behavior_counts[:screenshot_count].present? && behavior_counts[:screenshot_count].to_i > @quiz_attempt.screenshot_count.to_i
      @quiz_attempt.update(screenshot_count: behavior_counts[:screenshot_count])
    end

    if behavior_counts[:right_click_count].present? && behavior_counts[:right_click_count].to_i > @quiz_attempt.right_click_count.to_i
      @quiz_attempt.update(right_click_count: behavior_counts[:right_click_count])
    end

    if behavior_counts[:devtools_open_count].present? && behavior_counts[:devtools_open_count].to_i > @quiz_attempt.devtools_open_count.to_i
      @quiz_attempt.update(devtools_open_count: behavior_counts[:devtools_open_count])
    end

    if behavior_counts[:other_unusual_actions].present? && behavior_counts[:other_unusual_actions].to_i > @quiz_attempt.other_unusual_actions.to_i
      @quiz_attempt.update(other_unusual_actions: behavior_counts[:other_unusual_actions])
    end

    check_cheating_behavior
  end

  def check_cheating_behavior
    return unless @quiz_attempt.exceeds_cheating_threshold?

    if @quiz_attempt.quiz.exam?
      @quiz_attempt.auto_submit_for_cheating!
    else
      @quiz_attempt.mark_suspicious!('threshold_exceeded')
    end

    check_and_notify_cheating if @quiz_attempt.quiz.notify_cheating?
  end

  def check_and_notify_cheating
    return if @quiz_attempt.notified_at.present?

    SendCheatingAlertJob.perform_later(@quiz_attempt.id)
  end

  def handle_cheating_action(should_log: false)
    log_cheating_behavior(params[:action_type])
    log_client_action if should_log
    head :no_content
  end

  def handle_behavior_counts(should_log: false)
    update_behaviors(params[:behavior_counts])
    log_client_action if should_log
    head :no_content
  end

  def handle_state_update(should_log: false)
    state_data = params[:state_data]
    @quiz_attempt.update(time_spent: state_data[:elapsed_time].to_i,
                         current_question: state_data[:current_question].to_i)

    if state_data[:answers].present?
      answers_data = @quiz_attempt.answers_hash
      state_data[:answers].each do |question_id, answer|
        answers_data[question_id.to_s] = answer
      end
      @quiz_attempt.update(answers: answers_data.to_json)
    end

    log_client_action if should_log
    head :no_content
  end

  def handle_attempt_data(should_log: false)
    quiz_attempt_data = params[:quiz_attempt]

    if quiz_attempt_data[:current_question].present?
      @quiz_attempt.update(current_question: quiz_attempt_data[:current_question].to_i)
    end

    if quiz_attempt_data[:time_spent].present? || quiz_attempt_data[:elapsed_time].present?
      time_spent = quiz_attempt_data[:time_spent].presence || quiz_attempt_data[:elapsed_time]
      @quiz_attempt.update(time_spent: time_spent.to_i)
    end

    if quiz_attempt_data[:answers].present?
      answers_data = @quiz_attempt.answers_hash
      quiz_attempt_data[:answers].each do |question_id, answer|
        answers_data[question_id.to_s] = answer
      end
      @quiz_attempt.update(answers: answers_data.to_json)
    end

    log_client_action if should_log
    head :no_content
  end

  def log_client_action
    client_ip = params[:client_ip].presence || request.remote_ip
    @quiz_attempt.log_action({ client_ip: client_ip, device_info: request.user_agent })
  end
end
