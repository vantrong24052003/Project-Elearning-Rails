# frozen_string_literal: true

class Manage::QuestionsController < Manage::BaseController
  before_action :set_question, only: %i[show edit update destroy]

  def index
    @courses = if current_user.has_role?(:admin)
                 Course.all.order(:title)
               else
                 Course.where(user_id: current_user.id).order(:title)
               end

    if params[:ids].present? && params[:format] == 'json'
      question_ids = params[:ids].split(',')
      @questions = Question.where(id: question_ids).includes(:course)
      render json: { questions: @questions.as_json(include: { course: { only: [:id, :title] } }) }
      return
    end

    @questions = if params[:course_id].present?
                   Question.where(course_id: params[:course_id])
                 elsif params[:search].present?
                   Question.where('content ILIKE ?', "%#{params[:search]}%")
                 elsif current_user.has_role?(:admin)
                   Question.all
                 else
                   Question.where(user_id: current_user.id)
                 end

    @questions = @questions.order(created_at: :desc)
    @questions = filter_questions(@questions)
    @questions = @questions.page(params[:page]).per(12)
  end

  def show
    @question = Question.includes(:course, :user).find(params[:id])
  end

  def new
    @question = Question.new
    @courses = if current_user.has_role?(:admin)
                 Course.all.order(:title)
               else
                 Course.where(user_id: current_user.id).order(:title)
               end
  end

  def edit
    @courses = if current_user.has_role?(:admin)
                 Course.all.order(:title)
               else
                 Course.where(user_id: current_user.id).order(:title)
               end
  end

  def create
    if request.format.json? && params[:file].present? && params[:course_id].present?
      file = params[:file]
      course_id = params[:course_id]

      unless file.content_type.match?(%r{application/(vnd\.openxmlformats-officedocument\.spreadsheetml\.sheet|vnd\.ms-excel|csv)})
        render json: { error: 'Unsupported file format. Please use Excel (.xlsx, .xls) or CSV (.csv)' },
               status: :bad_request
        return
      end

      importer = QuestionsImportService.new(file, course_id, current_user.id)
      preview_results = importer.preview_import

      render json: preview_results
      return
    end

    if params[:preview_questions].present?
      begin
        questions_data = JSON.parse(params[:preview_questions])
        course_id = params[:selected_course_id]

        success_count = 0
        error_messages = []

        questions_data.each do |question_data|
          question = Question.new(
            content: question_data['content'],
            options: question_data['options'],
            correct_option: question_data['correct_option'],
            explanation: question_data['explanation'],
            difficulty: question_data['difficulty'],
            topic: question_data['topic'] || 'other',
            learning_goal: question_data['learning_goal'] || 'other',
            course_id: course_id,
            user_id: current_user.id,
            status: question_data['status'] || 'active',
            valid_until: question_data['valid_until'].present? ? Date.parse(question_data['valid_until'].to_s) : nil
          )

          if question.save
            success_count += 1
          else
            error_messages << "Câu hỏi '#{question.content[0..50]}...' lỗi: #{question.errors.full_messages.join(', ')}"
          end
        end

        if request.format.json?
          render json: { notice: true, message: "Successfully saved #{success_count} questions",
                         success_count: success_count, total: questions_data.size, errors: error_messages }
          return
        end

        if error_messages.any?
          flash[:alert] = "Successfully saved #{success_count}/#{questions_data.size} questions. Errors: #{error_messages.join('; ')}"
        else
          flash[:notice] = "Successfully saved #{success_count} questions"
        end

        redirect_to manage_questions_path
      rescue StandardError => e
        flash[:alert] = "An error occurred while saving questions: #{e.message}"
        redirect_to manage_questions_path
      end
      nil
    else
      @question = Question.new(question_params)
      @question.user_id = current_user.id

      if @question.save
        redirect_to manage_question_path(@question), notice: 'Question created successfully'
      else
        @courses = Course.all.order(:title)
        render :new, status: :unprocessable_entity
      end
    end
  end

  def update
    if @question.quizzes.where('end_time > ?', Time.current).exists? &&
       params[:question][:status].present? &&
       params[:question][:status] != 'active' &&
       @question.status == 'active'
      redirect_to manage_question_path(@question),
                  alert: 'This question is being used in a quiz that is currently active and cannot be changed.'
      return
    end

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
    params_with_options = params.require(:question).permit(:content, :correct_option, :explanation, :difficulty,
                                                           :course_id, :topic, :learning_goal, :status, :valid_until,
                                                           :options_0, :options_1, :options_2, :options_3)

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
    questions = questions.where(status: params[:status]) if params[:status].present?

    questions = questions.where(user_id: current_user.id) unless current_user.has_role?(:admin)

    questions
  end
end
