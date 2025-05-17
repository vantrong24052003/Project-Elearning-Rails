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
    if params[:file].present?
      unless File.extname(params[:file].original_filename) == ".xlsx"
        flash[:alert] = "Chỉ hỗ trợ file Excel (.xlsx)"
        @question = Question.new
        @courses = Course.all.order(:title)
        render :new, status: :unprocessable_entity
        return
      end

      if params[:course_id].blank?
        flash[:alert] = "Vui lòng chọn khóa học trước khi import"
        @question = Question.new
        @courses = Course.all.order(:title)
        render :new, status: :unprocessable_entity
        return
      end

      begin
        importer = QuestionsImportService.new(params[:file], params[:course_id], current_user.id)
        results = importer.import

        if results[:error].present?
          flash[:alert] = results[:error]
        elsif results[:failed] && results[:failed] > 0
          flash[:alert] = "Import hoàn tất với #{results[:success]}/#{results[:total]} câu hỏi thành công. #{results[:failed]} lỗi: #{results[:errors].join('; ')}"
        else
          flash[:notice] = "Import hoàn tất. Đã thêm #{results[:success]} câu hỏi mới."
        end
      rescue StandardError => e
        flash[:alert] = "Đã xảy ra lỗi khi import: #{e.message}"
      end

      redirect_to manage_questions_path
      return
    end

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
    if @question.quizzes.where('end_time > ?', Time.current).exists? &&
       params[:question][:status].present? &&
       params[:question][:status] != 'active' &&
       @question.status == 'active'
      redirect_to manage_question_path(@question), alert: 'Câu hỏi đang được sử dụng trong bài kiểm tra hiện đang diễn ra và không thể thay đổi trạng thái.'
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
    questions
  end
end
