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

  def show
    # Đảm bảo câu hỏi được tải đầy đủ
    @question = Question.includes(:course, :user).find(params[:id])
  end

  def new
    @question = Question.new
    @courses = Course.all.order(:title)
  end

  def edit
    @courses = Course.all.order(:title)
  end

  def create
    @question = Question.new(question_params)
    @question.user_id = current_user.id

    if @question.save
      redirect_to manage_question_path(@question), notice: 'Question created successfully'
    else
      @courses = Course.all.order(:title)
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @question.update(question_params)
      redirect_to manage_question_path(@question), notice: 'Question updated successfully'
    else
      @courses = Course.all.order(:title)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    quiz_questions = QuizQuestion.where(question_id: @question.id)

    if quiz_questions.any?
      redirect_to manage_questions_path, alert: 'This question is being used in quizzes and cannot be deleted.'
    else
      @question.destroy
      redirect_to manage_questions_path, notice: 'Question deleted successfully'
    end
  end

  private

  def set_question
    @question = Question.includes(:course, :user).find(params[:id])
  end

  def question_params
    params_with_options = params.require(:question).permit(:content, :correct_option, :explanation, :difficulty, :course_id, :topic, :learning_goal, :options_0, :options_1, :options_2, :options_3)

    options = {}
    (0..3).each do |i|
      options[i.to_s] = params_with_options.delete("options_#{i}")
    end

    params_with_options[:options] = options
    params_with_options
  end

  def filter_questions(questions)
    questions = questions.where(difficulty: params[:difficulty]) if params[:difficulty].present?
    questions = questions.where(topic: params[:topic]) if params[:topic].present?
    questions = questions.where(learning_goal: params[:learning_goal]) if params[:learning_goal].present?
    questions = questions.where(course_id: params[:course_id]) if params[:course_id].present?
    questions
  end
end
