# frozen_string_literal: true

class Dashboard::QuizAttemptsController < Dashboard::DashboardController
  before_action :set_course
  before_action :set_quiz
  before_action :set_quiz_attempt, only: %i[show edit update destroy]
  before_action :authenticate_user!
  before_action :check_ownership, only: [:show, :update, :edit, :destroy]

  def index
    @quiz_attempts = @quiz.quiz_attempts.where(user: current_user).order(created_at: :desc)
  end

  def show
    @questions = @quiz.questions
    mark_quiz_as_submitted(@quiz.id) if @quiz_attempt.completed_at.present?
  end

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
      formatted_answers = {}

      params[:answers]&.each do |question_id, selected_option|
        formatted_answers[question_id.to_s] = selected_option.to_i
        question = @quiz.questions.find_by(id: question_id)
        correct_answers += 1 if question && question.correct_option.to_i == selected_option.to_i
      end

      @quiz_attempt.answers = formatted_answers.to_json
      @quiz_attempt.score = (correct_answers.to_f / total_questions * 100).round(1)
      @quiz_attempt.completed_at = Time.current
      @quiz_attempt.time_spent = params[:time_spent].to_i

      if @quiz_attempt.save
        check_cheating_behavior

        session["quiz_#{@quiz.id}_submitted"] = true
        redirect_to dashboard_course_quiz_quiz_attempt_path(@course, @quiz, @quiz_attempt), notice: 'Bài làm đã được nộp thành công.'
      else
        redirect_to dashboard_course_quiz_path(@course, @quiz), alert: 'Có lỗi xảy ra khi nộp bài.'
      end
    else
      redirect_to dashboard_course_quiz_path(@course, @quiz, start: true), notice: 'Bắt đầu làm bài thành công.'
    end
  end

  def edit; end

  def update
    if params[:answers].present?
      correct_answers = 0
      total_questions = @quiz.questions.count
      formatted_answers = {}

      params[:answers]&.each do |question_id, selected_option|
        formatted_answers[question_id.to_s] = selected_option.to_i
        question = @quiz.questions.find_by(id: question_id)
        if question && question.correct_option.to_i == selected_option.to_i
          correct_answers += 1
        end
      end

      score = (correct_answers.to_f / total_questions * 100).round(1)
      time_spent = params[:time_spent].to_i

      if @quiz_attempt.update(
        score: score,
        time_spent: time_spent,
        answers: formatted_answers.to_json,
        completed_at: Time.current
      )
        check_cheating_behavior
        redirect_to dashboard_course_quiz_quiz_attempt_path(@course, @quiz, @quiz_attempt), notice: 'Bài làm đã được cập nhật thành công.'
      else
        redirect_to dashboard_course_quiz_path(@course, @quiz), alert: 'Có lỗi xảy ra khi cập nhật bài làm.'
      end
    else
      if params[:time_spent].present?
        if @quiz_attempt.update(time_spent: params[:time_spent].to_i, completed_at: Time.current)
          redirect_to dashboard_course_quiz_quiz_attempt_path(@course, @quiz, @quiz_attempt), notice: 'Bài làm đã được cập nhật.'
        else
          render :edit, status: :unprocessable_entity
        end
      elsif params[:quiz_attempt].present?
        quiz_attempt_params_with_completed = quiz_attempt_params.merge(completed_at: Time.current)
        if @quiz_attempt.update(quiz_attempt_params_with_completed)
          redirect_to dashboard_course_quiz_quiz_attempt_path(@course, @quiz, @quiz_attempt), notice: 'Bài làm đã được cập nhật.'
        else
          render :edit, status: :unprocessable_entity
        end
      else
        redirect_to dashboard_course_quiz_path(@course, @quiz), alert: 'Không có dữ liệu để cập nhật.'
      end
    end
  end

  def destroy
    @quiz_attempt.destroy
    redirect_to dashboard_course_quiz_attempts_path(@course, @quiz), notice: 'Bài làm đã được xóa.'
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

  def check_ownership
    return if current_user == @quiz_attempt.user

    redirect_to dashboard_course_quizzes_path(@course),
                alert: "Bạn không có quyền xem bài làm này."
  end

  def mark_quiz_as_submitted(quiz_id)
    session[:recent_submitted_quizzes] ||= []
    session[:recent_submitted_quizzes] << quiz_id.to_s
    session[:recent_submitted_quizzes].uniq!
  end

  def quiz_attempt_params
    params.require(:quiz_attempt).permit(:answers, :time_spent)
  end

end
