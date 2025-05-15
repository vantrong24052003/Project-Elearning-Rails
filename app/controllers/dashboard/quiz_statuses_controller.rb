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

    if action_type.present?
      log_cheating_behavior(action_type)
      head :no_content
    elsif behavior_counts.present?
      update_behaviors(behavior_counts)
      head :no_content
    elsif state_data.present?
      save_attempt_state(state_data)
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

  def save_attempt_state(state_data)
    return unless @quiz_attempt && current_user == @quiz_attempt.user

    if state_data[:current_question].present? || state_data[:elapsed_time].present? || state_data[:answers].present?
      @quiz_attempt.update(time_spent: state_data[:elapsed_time]) if state_data[:elapsed_time].present?

      @quiz_attempt.log_actions = [] if @quiz_attempt.log_actions.nil?
      @quiz_attempt.log_actions << {
        timestamp: Time.current.iso8601,
        action_type: 'save_state',
        current_question: state_data[:current_question],
        answers: state_data[:answers]
      }
      @quiz_attempt.save

      render json: { success: true, message: 'Đã lưu trạng thái bài làm' }, status: :ok
    else
      render json: { success: false, message: 'Dữ liệu không hợp lệ' }, status: :unprocessable_entity
    end
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
