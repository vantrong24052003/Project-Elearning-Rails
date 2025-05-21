# frozen_string_literal: true

class Dashboard::QuizAttemptsController < Dashboard::DashboardController
  before_action :set_course
  before_action :set_quiz
  before_action :set_quiz_attempt, only: %i[show update destroy]
  before_action :authenticate_user!
  before_action :check_ownership, only: %i[show update destroy]
  before_action :set_no_cache_headers, only: [:show]

  def show
    @questions = @quiz.questions
  end

  def update
    if params[:answers].present?
      correct_answers = 0
      total_questions = @quiz.questions.count
      formatted_answers = {}

      params[:answers]&.each do |question_id, selected_option|
        formatted_answers[question_id.to_s] = selected_option.to_i
        question = @quiz.questions.find_by(id: question_id)
        correct_answers += 1 if question && question.correct_option.to_i == selected_option.to_i
      end

      score = (correct_answers.to_f / total_questions * 10).round(1)
      time_spent = params[:time_spent].to_i

      if @quiz_attempt.update(
        score: score,
        time_spent: time_spent,
        answers: formatted_answers.to_json,
        completed_at: Time.current
      )
        client_ip = params[:client_ip].presence || request.remote_ip
        @quiz_attempt.log_action({
                                   client_ip: client_ip,
                                   device_info: request.user_agent
                                 })

        redirect_to dashboard_course_quiz_quiz_attempt_path(@course, @quiz, @quiz_attempt),
                    notice: 'The assignment has been updated successfully.'
      else
        redirect_to dashboard_course_quiz_path(@course, @quiz),
                    alert: 'An error occurred while updating the assignment.'
      end
    elsif params[:time_spent].present?
      if @quiz_attempt.update(
        time_spent: params[:time_spent].to_i,
        completed_at: Time.current
      )
        client_ip = params[:client_ip].presence || request.remote_ip
        @quiz_attempt.log_action({
                                   client_ip: client_ip,
                                   device_info: request.user_agent
                                 })

        redirect_to dashboard_course_quiz_quiz_attempt_path(@course, @quiz, @quiz_attempt),
                    notice: 'The assignment has been updated.'
      end
    elsif params[:quiz_attempt].present?
      quiz_attempt_params_with_completed = quiz_attempt_params.merge(
        completed_at: Time.current
      )
      if @quiz_attempt.update(quiz_attempt_params_with_completed)
        client_ip = params[:client_ip].presence || request.remote_ip
        @quiz_attempt.log_action({
                                   client_ip: client_ip,
                                   device_info: request.user_agent
                                 })

        redirect_to dashboard_course_quiz_quiz_attempt_path(@course, @quiz, @quiz_attempt),
                    notice: 'The assignment has been updated.'
      end
    else
      redirect_to dashboard_course_quiz_path(@course, @quiz), alert: 'There is no data to update.'
    end
  end

  def destroy
    @quiz_attempt.destroy
    redirect_to dashboard_course_quiz_path(@course), notice: 'Bài làm đã được xóa.'
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
    @quiz = @course.quizzes.find(params[:quiz_id])
  end

  def set_quiz_attempt
    @quiz_attempt = @quiz.quiz_attempts.find(params[:id])
  end

  def check_ownership
    return if current_user == @quiz_attempt.user

    redirect_to dashboard_course_quizzes_path(@course),
                alert: 'You are not authorized to view this quiz attempt.'
  end

  def quiz_attempt_params
    params.require(:quiz_attempt).permit(:answers, :time_spent)
  end
end
