# frozen_string_literal: true

class Manage::QuizzesController < Manage::BaseController
  before_action :set_quiz, only: %i[show edit update destroy]
  before_action :set_courses, only: %i[new edit]

  def index
    @quizzes = Quiz.includes(:course, :questions).order(created_at: :desc).page(params[:page]).per(10)
  end

  def show
    @analysis = {
      concept_count: rand(5..15),
      coverage: rand(70..98),
      suggestions: [
        'Bổ sung thêm ví dụ thực tế để làm rõ khái niệm',
        'Thêm câu hỏi về ứng dụng thực tiễn',
        'Tăng độ phủ của các khái niệm nâng cao'
      ].sample(rand(1..3))
    }
  end

  def new
    @quiz = Quiz.new
  end

  def edit; end

  def create
    @quiz = Quiz.new(quiz_params)

    if params[:source_type] == 'ai_generated' && params[:questions_data].present?
      begin
        questions_data = JSON.parse(params[:questions_data])

        if @quiz.save
          questions_data.each do |q_data|
            question = Question.new(
              content: q_data['content'],
              options: q_data['options'],
              correct_option: q_data['correct_option'],
              explanation: q_data['explanation'],
              difficulty: q_data['difficulty'],
              course_id: @quiz.course_id,
              user_id: current_user.id
            )

            if question.save
              QuizQuestion.create(quiz: @quiz, question: question)
            end
          end

          redirect_to manage_quiz_path(@quiz), notice: 'Quiz was successfully created with AI generated questions.'
        else
          set_courses
          render :new, status: :unprocessable_entity
        end
      rescue JSON::ParserError
        set_courses
        @quiz.errors.add(:base, 'Invalid questions data format')
        render :new, status: :unprocessable_entity
      end
    else
      if @quiz.save
        redirect_to manage_quiz_path(@quiz), notice: 'Quiz was successfully created.'
      else
        set_courses
        render :new, status: :unprocessable_entity
      end
    end
  end

  def update
    if @quiz.update(quiz_params)
      redirect_to manage_quiz_path(@quiz), notice: 'Quiz was successfully updated.'
    else
      set_courses
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @quiz.destroy!
    redirect_to manage_quizzes_path, notice: 'Quiz was successfully destroyed.'
  end

  private

  def set_quiz
    @quiz = Quiz.includes(questions: [:quiz_questions]).find(params[:id])
  end

  def set_courses
    @courses = Course.all.order(:title)
  end

  def quiz_params
    params.require(:quiz).permit(:title, :is_exam, :time_limit, :course_id)
  end
end
