# frozen_string_literal: true

class Dashboard::QuizAttemptsController < Dashboard::DashboardController
  before_action :set_course
  before_action :set_quiz
  before_action :set_quiz_attempt, only: %i[show edit update destroy log_action update_behavior_counts]
  before_action :authenticate_user!

  def index
    @quiz_attempts = @quiz.quiz_attempts.where(user: current_user).order(created_at: :desc)
  end

  def in_progress
    @course = Course.find(params[:course_id])

    @quiz_attempts = QuizAttempt.joins(:quiz)
                                .where(quizzes: { course_id: @course.id }, user: current_user)
                                .select('quiz_attempts.id, quiz_attempts.quiz_id, quiz_attempts.completed_at')

    render json: @quiz_attempts
  end

  def show; end

  def new
    @quiz_attempt = @quiz.quiz_attempts.build
  end

  def create
    @quiz_attempt = @quiz.quiz_attempts
                         .where(user: current_user)
                         .where(completed_at: nil)
                         .order(created_at: :desc)
                         .first

    if @quiz_attempt.nil?
      @quiz_attempt = @quiz.quiz_attempts.build
      @quiz_attempt.user = current_user
      @quiz_attempt.start_time = Time.current
      @quiz_attempt.device_info = request.user_agent
      @quiz_attempt.ip_address = request.remote_ip

      unless @quiz_attempt.save
        redirect_to dashboard_course_quiz_path(@course, @quiz), alert: 'Có lỗi xảy ra khi bắt đầu làm bài.'
        return
      end
    end

    if params[:answers].present?
      correct_answers = 0
      total_questions = @quiz.questions.count

      params[:answers]&.each do |question_id, selected_option|
        question = @quiz.questions.find(question_id)
        correct_answers += 1 if question.correct_option.to_i == selected_option.to_i
      end

      @quiz_attempt.answers = params[:answers].to_json
      @quiz_attempt.score = (correct_answers.to_f / total_questions * 100).round(1)
      @quiz_attempt.completed_at = Time.current
      @quiz_attempt.time_spent = params[:time_spent].to_i

      if @quiz_attempt.save
        notify_instructor_of_cheating if @quiz_attempt.check_cheating_behavior

        redirect_to dashboard_course_quiz_attempt_path(@course, @quiz, @quiz_attempt),
                    notice: 'Bài làm đã được nộp thành công.'
      else
        redirect_to dashboard_course_quiz_path(@course, @quiz), alert: 'Có lỗi xảy ra khi nộp bài.'
      end
    else
      redirect_to dashboard_course_quiz_path(@course, @quiz, start: true), notice: 'Bắt đầu làm bài thành công.'
    end
  end

  def edit; end

  def update
    if @quiz_attempt.update(quiz_attempt_params)
      redirect_to dashboard_course_quiz_attempt_path(@course, @quiz, @quiz_attempt), notice: 'Bài làm đã được cập nhật.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @quiz_attempt.destroy
    redirect_to dashboard_course_quiz_attempts_path(@course, @quiz), notice: 'Bài làm đã được xóa.'
  end

  def log_action
    action_type = params[:action_type]

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

    render json: { success: true }
  end

  def update_behavior_counts
    counts = params.permit(
      :tab_switch_count,
      :copy_paste_count,
      :screenshot_count,
      :right_click_count,
      :devtools_open_count,
      :other_unusual_actions
    )

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

    render json: { success: true, updated: true }
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_quiz
    @quiz = @course.quizzes.find(params[:quiz_id])
  end

  def set_quiz_attempt
    @quiz_attempt = @quiz.quiz_attempts.find(params[:id])
  end

  def quiz_attempt_params
    params.require(:quiz_attempt).permit(:answers, :time_spent)
  end

  def check_cheating_behavior
    return unless @quiz.is_exam?

    suspicious_behavior = false

    suspicious_behavior = true if @quiz_attempt.tab_switch_count.to_i >= 5

    suspicious_behavior = true if @quiz_attempt.copy_paste_count.to_i >= 3

    suspicious_behavior = true if @quiz_attempt.screenshot_count.to_i >= 2

    suspicious_behavior = true if @quiz_attempt.right_click_count.to_i >= 3

    suspicious_behavior = true if @quiz_attempt.devtools_open_count.to_i >= 2

    suspicious_behavior = true if @quiz_attempt.other_unusual_actions.to_i >= 3

    notify_instructor_of_cheating if suspicious_behavior
  end

  def notify_instructor_of_cheating
    return if @quiz_attempt.is_notified

    @quiz_attempt.update(
      is_notified: true,
      notified_at: Time.current
    )

    CourseMailer.cheating_notification(
      @course.user,
      @quiz_attempt
    ).deliver_later
  end
end
