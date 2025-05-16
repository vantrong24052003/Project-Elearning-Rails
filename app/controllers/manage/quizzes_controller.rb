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

     respond_to do |format|
      format.html
      format.json do
        if params[:get_content_type] == 'course_chapters'
          render json: get_course_chapters
        elsif params[:get_content_type] == 'chapter_lessons'
          render json: get_chapter_lessons
        elsif params[:get_content_type] == 'lesson_videos'
          render json: get_lesson_videos
        elsif params[:get_content_type] == 'video_details'
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

        # Xử lý xóa câu hỏi
        if params[:delete_question_id].present?
          question_to_delete = Question.find_by(id: params[:delete_question_id])
          if question_to_delete && question_to_delete.quizzes.include?(@quiz)
            QuizQuestion.where(quiz: @quiz, question: question_to_delete).destroy_all
            # Nếu câu hỏi này chỉ thuộc về quiz này, xóa luôn câu hỏi
            if question_to_delete.quizzes.count == 0
              question_to_delete.destroy
            end
            flash[:notice] = 'Câu hỏi đã được xóa khỏi bài kiểm tra.'
          end
        end

        # Cập nhật các câu hỏi
        questions_data.each do |q_data|
          question = Question.find_by(id: q_data['id'])
          next unless question && question.quizzes.include?(@quiz)

          question.update(
            content: q_data['content'],
            options: q_data['options'],
            correct_option: q_data['correct_option'],
            explanation: q_data['explanation'],
            difficulty: q_data['difficulty']
          )
        end

        redirect_to manage_quiz_path(@quiz), notice: 'Bài kiểm tra đã được cập nhật thành công.'
        return
      rescue JSON::ParserError
        flash[:alert] = 'Dữ liệu câu hỏi không hợp lệ.'
        redirect_to manage_quiz_path(@quiz)
        return
      rescue => e
        Rails.logger.error("Lỗi khi cập nhật câu hỏi: #{e.message}")
        flash[:alert] = "Lỗi khi cập nhật câu hỏi: #{e.message}"
        redirect_to manage_quiz_path(@quiz)
        return
      end
    end

    # Xử lý cập nhật thông tin cơ bản của quiz
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

  def create_questions_from_transcription
    title = params[:title]
    description = params[:description]
    num_questions = params[:num_questions].to_i || 5
    difficulty = params[:difficulty] || 'medium'

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
        difficulty: difficulty
      )

      if questions.blank? || !questions.is_a?(Array) || questions.empty?
        render json: { error: 'Không thể tạo câu hỏi từ nội dung phiên âm này' }, status: :unprocessable_entity
        return
      end

      render json: questions, status: :ok
    rescue => e
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
      if transcription_value.present?
        result[:transcription] = transcription_value
      else
        result[:transcription] = "Chưa có phiên âm cho video này."
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
