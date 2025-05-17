# frozen_string_literal: true

class Manage::QuestionsController < Manage::BaseController
  before_action :set_question, only: %i[show edit update destroy]

  def index
    @courses = Course.all.order(:title)

    @questions = if params[:course_id].present?
                   Question.where(course_id: params[:course_id])
                 elsif params[:search].present?
                   Question.where('content ILIKE ?', "%#{params[:search]}%")
                 else
                   Question.all
                 end

    @questions = @questions.order(created_at: :desc)
    @questions = filter_questions(@questions)
    @questions = @questions.page(params[:page]).per(12)
  end

  def show; end

  def new; end

  def edit; end

  def destroy; end

  def create; end

  def update; end

  private

  def set_question
    @question = Question.find(params[:id])
  end

  def question_params
    params.require(:question).permit(:content, :correct_option, :explanation, :difficulty, :course_id, :topic,
                                     :learning_goal, options: {})
  end

  def filter_questions(questions)
    questions = questions.where(difficulty: params[:difficulty]) if params[:difficulty].present?
    questions = questions.where(topic: params[:topic]) if params[:topic].present?
    questions = questions.where(learning_goal: params[:learning_goal]) if params[:learning_goal].present?
    questions = questions.where(course_id: params[:course_id]) if params[:course_id].present?
    questions
  end
end
