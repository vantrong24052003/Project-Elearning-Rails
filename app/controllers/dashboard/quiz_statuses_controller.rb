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

    if action_type.present?
      log_cheating_behavior
      render json: { success: true }
    elsif behavior_counts.present?
      sync_behaviors
      render json: { success: true, updated: true }
    else
      render json: { error: 'Không có dữ liệu' }, status: :unprocessable_entity
    end
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_quiz_attempt
    quiz_id = params[:quiz_id]
    attempt_id = params[:id]
    @quiz = @course.quizzes.find(quiz_id)
    @quiz_attempt = QuizAttempt.find(attempt_id)
  end

  def log_cheating_behavior
    action_type = params[:action_type]

    # Ghi log chi tiết vào log_actions
    @quiz_attempt.log_action(action_type, {
      client_ip: request.remote_ip,
      details: params[:details]
    })

    # Cập nhật counter cho loại hành vi
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

  def sync_behaviors
    counts = params[:behavior_counts]

    if counts[:tab_switch_count].present? && counts[:tab_switch_count].to_i > @quiz_attempt.tab_switch_count.to_i
      @quiz_attempt.update(tab_switch_count: counts[:tab_switch_count])
    end

    if counts[:copy_paste_count].present? && counts[:copy_paste_count].to_i > @quiz_attempt.copy_paste_count.to_i
      @quiz_attempt.update(copy_paste_count: counts[:copy_paste_count])
    end

    if counts[:screenshot_count].present? && counts[:screenshot_count].to_i > @quiz_attempt.screenshot_count.to_i
      @quiz_attempt.update(screenshot_count: counts[:screenshot_count])
    end

    if counts[:right_click_count].present? && counts[:right_click_count].to_i > @quiz_attempt.right_click_count.to_i
      @quiz_attempt.update(right_click_count: counts[:right_click_count])
    end

    if counts[:devtools_open_count].present? && counts[:devtools_open_count].to_i > @quiz_attempt.devtools_open_count.to_i
      @quiz_attempt.update(devtools_open_count: counts[:devtools_open_count])
    end

    if counts[:other_unusual_actions].present? && counts[:other_unusual_actions].to_i > @quiz_attempt.other_unusual_actions.to_i
      @quiz_attempt.update(other_unusual_actions: counts[:other_unusual_actions])
    end

    check_cheating_behavior
  end

  def check_cheating_behavior
    return unless @quiz_attempt.quiz.is_exam?

    suspicious_behavior = false
    suspicious_behavior = true if @quiz_attempt.tab_switch_count.to_i >= 5
    suspicious_behavior = true if @quiz_attempt.copy_paste_count.to_i >= 3
    suspicious_behavior = true if @quiz_attempt.screenshot_count.to_i >= 2
    suspicious_behavior = true if @quiz_attempt.right_click_count.to_i >= 3
    suspicious_behavior = true if @quiz_attempt.devtools_open_count.to_i >= 2
    suspicious_behavior = true if @quiz_attempt.other_unusual_actions.to_i >= 3

    @quiz_attempt.update(suspicious_behavior: suspicious_behavior) if @quiz_attempt.suspicious_behavior != suspicious_behavior
  end

  def check_and_notify_cheating
    return unless @quiz_attempt.quiz.is_exam?
    return if @quiz_attempt.is_notified
    return unless @quiz_attempt.suspicious_behavior
    return unless @quiz_attempt.completed_at.present?

    CourseMailer.cheating_notification(
      @course.user,
      @quiz_attempt
    ).deliver_later

    @quiz_attempt.update(is_notified: true, notified_at: Time.current)
  end
end
