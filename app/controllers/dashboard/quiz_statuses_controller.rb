# frozen_string_literal: true

class Dashboard::QuizStatusesController < Dashboard::DashboardController
  before_action :set_course
  before_action :set_quiz_attempt, only: [:update]
  before_action :authenticate_user!

  def index
    @quiz_attempts = QuizAttempt.joins(:quiz)
                                .where(quizzes: { course_id: @course.id }, user: current_user)
                                .select('quiz_attempts.id, quiz_attempts.quiz_id, quiz_attempts.completed_at')
    render json: @quiz_attempts
  end

  def update
    action_type = params[:action_type]
    behavior_counts = params[:behavior_counts]
    state_data = params[:state_data]
    quiz_attempt_data = params[:quiz_attempt]

    client_ip = params[:client_ip].presence || request.remote_ip

    if action_type.present?
      log_cheating_behavior(action_type)

      @quiz_attempt.log_action({
                                 client_ip: client_ip,
                                 device_info: request.user_agent
                               })

      head :no_content
    elsif behavior_counts.present?
      update_behaviors(behavior_counts)

      @quiz_attempt.log_action({
                                 client_ip: client_ip,
                                 device_info: request.user_agent
                               })

      head :no_content
    elsif state_data.present?
      @quiz_attempt.update(
        time_spent: state_data[:elapsed_time].to_i,
        current_question: state_data[:current_question].to_i
      )

      if state_data[:answers].present?
        answers_data = @quiz_attempt.answers_hash
        state_data[:answers].each do |question_id, answer|
          answers_data[question_id.to_s] = answer
        end
        @quiz_attempt.update(answers: answers_data.to_json)
      end

      @quiz_attempt.log_action({
                                 client_ip: client_ip,
                                 device_info: request.user_agent
                               })

      head :no_content
    elsif quiz_attempt_data.present?
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

      @quiz_attempt.log_action({
                                 client_ip: client_ip,
                                 device_info: request.user_agent
                               })

      head :no_content
    else
      render json: { error: 'No data' }, status: :unprocessable_entity
    end
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
    return unless @quiz_attempt.quiz.is_exam?

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
    return unless @quiz_attempt.quiz.is_exam?

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
    suspicious_behavior = false
    suspicious_behavior = true if @quiz_attempt.tab_switch_count.to_i >= 5
    suspicious_behavior = true if @quiz_attempt.copy_paste_count.to_i >= 3
    suspicious_behavior = true if @quiz_attempt.screenshot_count.to_i >= 2
    suspicious_behavior = true if @quiz_attempt.right_click_count.to_i >= 3
    suspicious_behavior = true if @quiz_attempt.devtools_open_count.to_i >= 2
    suspicious_behavior = true if @quiz_attempt.other_unusual_actions.to_i >= 3

    check_and_notify_cheating if suspicious_behavior
  end

  def check_and_notify_cheating
    return unless @quiz_attempt.completed_at.present?

    CourseMailer.cheating_notification(
      @course.user,
      @quiz_attempt
    ).deliver_later

    @quiz_attempt.update(notified_at: Time.current)
  end
end
