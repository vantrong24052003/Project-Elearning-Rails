# frozen_string_literal: true

class Dashboard::AttemptsController < Dashboard::DashboardController
  before_action :set_course
  before_action :set_quiz, only: [:create]
  before_action :set_attempt, only: [:show]
  before_action :check_ownership, only: [:show]
  after_action :clear_session_data, only: [:create]


  def show
    @questions = @attempt.quiz.questions
    mark_quiz_as_submitted(@attempt.quiz_id)
  end

  def create
    answers = params[:answers] || {}
    time_spent = params[:time_spent].to_i
    total_questions = @quiz.questions.count
    correct_count = 0
    formatted_answers = {}

    answers.each do |question_id, answer|
      formatted_answers[question_id.to_s] = answer.to_i
      question = Question.find_by(id: question_id)
      correct_count += 1 if question && answer.to_i == question.correct_option
    end

    score = total_questions.positive? ? (correct_count.to_f / total_questions * 100).round : 0

    @attempt = QuizAttempt.new(
      quiz: @quiz,
      user: current_user,
      score: score,
      time_spent: time_spent,
      answers: formatted_answers
    )

    if @attempt.save
      session["quiz_#{@quiz.id}_submitted"] = true

      redirect_to dashboard_course_quiz_attempt_path(@course, @quiz, @attempt),
                  notice: 'Your quiz has been submitted successfully.'
    else
      redirect_to dashboard_course_quiz_path(@course, @quiz),
                  alert: 'There was an error submitting your quiz. Please try again.'
    end
  end

  def destroy
    @attempt.destroy
    redirect_to dashboard_course_quiz_attempts_path(@course, @quiz),
                notice: 'Lần làm bài đã được xóa.'
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_quiz
    @quiz = @course.quizzes.find(params[:quiz_id])
  end

  def set_attempt
    @attempt = QuizAttempt.find(params[:id])
    @quiz = @attempt.quiz
  end

  def check_ownership
    return if current_user == @attempt.user

    redirect_to dashboard_course_quizzes_path(@course),
                alert: "You don't have permission to view this attempt."
  end

  def mark_quiz_as_submitted(quiz_id)
    session[:recent_submitted_quizzes] ||= []
    session[:recent_submitted_quizzes] << quiz_id.to_s
    session[:recent_submitted_quizzes].uniq!
  end

  def clear_session_data
    response.headers['X-Clear-Quiz-Storage'] = "quiz_#{@quiz.id}"
    response.headers['X-Quiz-Is-Exam'] = @quiz.is_exam?.to_s
    response.headers['X-Quiz-Submitted'] = 'true'
  end
end
