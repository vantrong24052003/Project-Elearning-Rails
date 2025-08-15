# frozen_string_literal: true

class Dashboard::QuizzesController < Dashboard::DashboardController
  before_action :set_course
  before_action :set_quiz, only: [:show]
  before_action :check_enrollment, only: [:show]
  before_action :load_stats_data, only: [:index]
  before_action :authenticate_user!
  before_action :set_no_cache_headers, only: [:show]

  def index
    @available_quizzes = @course.quizzes.available.order(created_at: :desc).page(params[:page]).per(10)
    @upcoming_quizzes = @course.quizzes.upcoming.order(created_at: :desc)
    @expired_quizzes = @course.quizzes.expired.order(created_at: :desc)
  end

  def show
    @questions = @quiz.questions
    @mode = @quiz.exam? ? 'exam' : 'practice'

    service = Dashboard::QuizzesService.new
    completed = service.latest_completed_attempt(@quiz, current_user)
    if @quiz.exam? && completed.present?
      redirect_to dashboard_course_quiz_quiz_attempt_path(@course, @quiz, completed),
                  notice: 'You have completed this test. Here are your results.'
      return
    end

    @quiz_attempt = service.in_progress_attempt(@quiz, current_user)
    if params[:start] == 'true' && @quiz_attempt.nil?
      @quiz_attempt = service.start_attempt_if_needed!(@quiz, current_user,
                                                       (params[:client_ip].presence || request.remote_ip), request.user_agent)
    end
  end

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

  def set_no_cache_headers
    response.headers['Cache-Control'] = 'no-cache, no-store, max-age=0, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = 'Fri, 01 Jan 1990 00:00:00 GMT'
  end

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_quiz
    @quiz = @course.quizzes.find(params[:id])
  end

  def check_enrollment
    return if current_user.has_role?(:admin)
    return if current_user == @course.user
    return if current_user && Enrollment.exists?(user: current_user, course: @course, status: :active)

    redirect_to dashboard_course_path(@course),
                alert: 'You need to enroll in this course to take quizzes.'
  end

  def load_stats_data
    @stats = Dashboard::StatsQuizzesService.call(course: @course, user: current_user)
  end

  def quiz_params
    params.require(:quiz).permit(:title, :is_exam, :time_limit, :start_time, :end_time, :notify_cheating)
  end
end
