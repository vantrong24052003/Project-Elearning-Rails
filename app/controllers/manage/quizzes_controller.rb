# frozen_string_literal: true

class Manage::QuizzesController < Manage::BaseController
  before_action :set_quiz, only: %i[show edit update destroy]
  before_action :set_courses, only: %i[new edit]
  def index
    @quizzes = if params[:course_id].present?
                 Quiz.includes(:course,
                               :questions).where(course_id: params[:course_id]).order(created_at: :desc).page(params[:page]).per(10)
               else
                 Quiz.includes(:course, :questions).order(created_at: :desc).page(params[:page]).per(10)
               end

    @course = Course.find_by(id: params[:course_id]) if params[:course_id].present?
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

    if params[:course_id].present?
      @quiz.course_id = params[:course_id]
      @course = Course.find_by(id: params[:course_id])
    end

    respond_to do |format|
      format.html
      format.json do
        case params[:get_content_type]
        when 'course_chapters'
          render json: get_course_chapters
        when 'chapter_lessons'
          render json: get_chapter_lessons
        when 'lesson_videos'
          render json: get_lesson_videos
        when 'video_details'
          render json: get_video_details
        else
          render json: { error: 'Invalid content type' }, status: :unprocessable_entity
        end
      end
    end
  end

  def edit; end

  def create
    if request.format.json? && params[:title].present? && params[:description].present?
      create_questions_from_transcription
      return
    end

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
              topic: q_data['topic'],
              learning_goal: q_data['learning_goal'],
              course_id: @quiz.course_id,
              user_id: current_user.id
            )

            QuizQuestion.create(quiz: @quiz, question: question) if question.save
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
    elsif @quiz.save
      redirect_to manage_quiz_path(@quiz), notice: 'Quiz was successfully created.'
    else
      set_courses
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if params[:update_questions].present? && params[:questions_data].present?
      begin
        questions_data = JSON.parse(params[:questions_data])

        if params[:delete_question_id].present?
          question_to_delete = Question.find_by(id: params[:delete_question_id])
          if question_to_delete&.quizzes&.include?(@quiz)
            QuizQuestion.where(quiz: @quiz, question: question_to_delete).destroy_all
            question_to_delete.destroy if question_to_delete.quizzes.count.zero?
            flash[:notice] = 'Câu hỏi đã được xóa khỏi bài kiểm tra.'
          end
        end

        questions_data.each do |q_data|
          question = Question.find_by(id: q_data['id'])
          next unless question&.quizzes&.include?(@quiz)

          question.update(
            content: q_data['content'],
            options: q_data['options'],
            correct_option: q_data['correct_option'],
            explanation: q_data['explanation'],
            difficulty: q_data['difficulty'],
            topic: q_data['topic'],
            learning_goal: q_data['learning_goal']
          )
        end

        redirect_to manage_quiz_path(@quiz), notice: 'Bài kiểm tra đã được cập nhật thành công.'
        return
      rescue JSON::ParserError
        flash[:alert] = 'Dữ liệu câu hỏi không hợp lệ.'
        redirect_to manage_quiz_path(@quiz)
        return
      rescue StandardError => e
        Rails.logger.error("Lỗi khi cập nhật câu hỏi: #{e.message}")
        flash[:alert] = "Lỗi khi cập nhật câu hỏi: #{e.message}"
        redirect_to manage_quiz_path(@quiz)
        return
      end
    end

    if @quiz.update(quiz_params)
      redirect_to manage_quiz_path(@quiz), notice: 'Quiz was successfully updated.'
    else
      set_courses
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    questions = @quiz.questions.to_a
    QuizQuestion.where(quiz_id: @quiz.id).destroy_all

    questions.each do |question|
      count = QuizQuestion.where(question_id: question.id).count
      question.destroy if count.zero?
    end

    @quiz.destroy!

    redirect_to manage_quizzes_path, notice: 'Bài kiểm tra đã được xóa thành công.'
  end

  private

  def create_questions_from_transcription
    title = params[:title]
    description = params[:description]
    num_questions = params[:num_questions].to_i || 5
    difficulty = params[:difficulty] || 'medium'
    topic = params[:topic] || 'other'
    learning_goal = params[:learning_goal] || 'other'

    if description.blank? || title.blank?
      render json: { error: 'Thiếu thông tin cần thiết' }, status: :bad_request
      return
    end

    gemini_service = GeminiServices.new
    begin
      questions = gemini_service.generate_quiz(
        title: title,
        description: description,
        num_questions: num_questions,
        difficulty: difficulty,
        topic: topic,
        learning_goal: learning_goal
      )

      if questions.blank? || !questions.is_a?(Array) || questions.empty?
        render json: { error: 'Không thể tạo câu hỏi từ nội dung phiên âm này' }, status: :unprocessable_entity
        return
      end

      render json: questions, status: :ok
    rescue StandardError => e
      Rails.logger.error("Lỗi khi tạo câu hỏi từ phiên âm: #{e.message}")
      render json: { error: "Không thể tạo câu hỏi: #{e.message}" }, status: :unprocessable_entity
    end
  end

  def get_course_chapters
    course = Course.find(params[:course_id])
    course.chapters.order(position: :asc).map { |chapter| { id: chapter.id, title: chapter.title } }
  end

  def get_chapter_lessons
    chapter = Chapter.find(params[:chapter_id])
    chapter.lessons.order(position: :asc).map { |lesson| { id: lesson.id, title: lesson.title } }
  end

  def get_lesson_videos
    lesson = Lesson.find(params[:lesson_id])
    lesson.videos.order(position: :asc).map { |video| { id: video.id, title: video.title } }
  end

  def get_video_details
    video = Video.find_by(id: params[:video_id])
    return if video.nil?

    result = { id: video.id, title: video.title }

    if video.upload.present?
      upload = video.upload

      transcription_value = upload.transcription
      result[:transcription] = if transcription_value.present?
                                 transcription_value
                               else
                                 'Chưa có phiên âm cho video này.'
                               end
    end

    result
  end

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
