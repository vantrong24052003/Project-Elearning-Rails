# frozen_string_literal: true

class Dashboard::QuizzesController < Dashboard::DashboardController
  before_action :set_course
  before_action :set_quiz, only: [:show, :edit, :update, :destroy]
  before_action :check_enrollment, only: [:show]

  def index
    @quizzes = @course.quizzes.where(is_exam: false).order(created_at: :desc)
  end

  def show
    @questions = @quiz.questions
    @attempt_id = params[:attempt_id]

    if @attempt_id.present? && params[:show_results].present?
      @attempt = QuizAttempt.find_by(id: @attempt_id)

      if @attempt.nil?
        redirect_to dashboard_course_quizzes_path(@course), alert: 'Quiz attempt not found.'
        return
      end

      redirect_to dashboard_course_quiz_attempt_path(@course, @quiz, @attempt) and return
    end

    @practice_attempts = QuizAttempt.where(quiz: @quiz, user: current_user)
                                    .order(created_at: :desc)
                                    .limit(5)
                                    .select { |attempt| !@quiz.is_exam }
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

  def edit
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

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_quiz
    @quiz = @course.quizzes.find(params[:id])
  end

  def check_enrollment
    if !current_user.enrollments.active.exists?(course: @course)
      redirect_to dashboard_course_path(@course), alert: 'You need to enroll in this course to take quizzes'
    end
  end

  def quiz_params
    params.require(:quiz).permit(:title, :is_exam, :time_limit)
  end
end
