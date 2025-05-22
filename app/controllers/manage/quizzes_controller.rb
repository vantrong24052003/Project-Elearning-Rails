# frozen_string_literal: true

class Manage::QuizzesController < Manage::BaseController
  before_action :set_quiz, only: %i[show edit update destroy]
  before_action :set_courses, only: %i[new edit]

  def index
    @quizzes = if params[:course_id].present?
                 Quiz.includes(:course, :questions).where(course_id: params[:course_id])
               else
                 Quiz.includes(:course, :questions)
               end
    @quizzes = @quizzes.where(is_exam: params[:is_exam]) if params[:is_exam].present?
    @quizzes = @quizzes.order(created_at: :desc).page(params[:page]).per(10)
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
    @quiz = Quiz.find(params[:id])
    @courses = Course.where(user_id: current_user.id).order(:title)
  end

  def new_with_preview
    session[:preview_questions_data] = params[:preview_questions_data] if params[:preview_questions_data].present?
    redirect_to new_manage_quiz_path
  end

  def new
    @quiz = Quiz.new

    if params[:course_id].present?
      @course = Course.find_by(id: params[:course_id], user_id: current_user.id)
      @quiz.course_id = @course.id if @course
    end

    if session[:preview_questions_data].present?
      @preview_questions_data = session[:preview_questions_data]
      session.delete(:preview_questions_data)
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

    unless validate_quiz_time(@quiz)
      flash.now[:alert] = @quiz.errors.full_messages.join(", ")
      set_courses
      return render :new, status: :unprocessable_entity
    end

    if params[:selected_questions_data].present?
      selected_questions_data = JSON.parse(params[:selected_questions_data])

      if @quiz.save
        selected_questions_data.each do |question_data|
          question = if question_data['id'].present?
                      Question.find_by(id: question_data['id'])
                    else
                      nil
                    end

          if question
            QuizQuestion.create(quiz: @quiz, question: question)
          else
            new_question = Question.new(
              content: question_data['content'],
              options: question_data['options'],
              correct_option: question_data['correct_option'],
              explanation: question_data['explanation'] || 'Không có giải thích',
              difficulty: question_data['difficulty'] || 'medium',
              topic: question_data['topic'] || 'other',
              learning_goal: question_data['learning_goal'] || 'other',
              course_id: @quiz.course_id,
              user_id: current_user.id,
              status: 'active'
            )

            if new_question.save
              QuizQuestion.create(quiz: @quiz, question: new_question)
            else
              Rails.logger.error("Không thể lưu câu hỏi: #{new_question.errors.full_messages.join(', ')}")
            end
          end
        end

        redirect_to manage_quiz_path(@quiz), notice: 'Bài kiểm tra đã được tạo thành công với câu hỏi đã chọn'
      else
        set_courses
        render :new, status: :unprocessable_entity
      end
    elsif params[:preview_questions_data].present?
      preview_questions = JSON.parse(params[:preview_questions_data])

      if @quiz.save
        preview_questions.each do |q_data|
          question = Question.new(
            content: q_data['content'],
            options: q_data['options'],
            correct_option: q_data['correct_option'],
            explanation: q_data['explanation'] || 'Không có giải thích',
            difficulty: q_data['difficulty'] || 'medium',
            topic: q_data['topic'] || 'other',
            learning_goal: q_data['learning_goal'] || 'other',
            course_id: @quiz.course_id,
            user_id: current_user.id,
            status: 'active'
          )

          if question.save
            QuizQuestion.create(quiz: @quiz, question: question)
          else
            Rails.logger.error("Không thể lưu câu hỏi: #{question.errors.full_messages.join(', ')}")
          end
        end

        redirect_to manage_quiz_path(@quiz), notice: 'Bài kiểm tra đã được tạo thành công với câu hỏi từ preview'
      else
        set_courses
        render :new, status: :unprocessable_entity
      end
    elsif params[:questions_data].present?
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
            flash[:notice] = 'Question has been removed from the quiz.'
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

        redirect_to manage_quiz_path(@quiz), notice: 'Quiz was successfully updated.'
        return
      rescue JSON::ParserError
        flash[:alert] = 'Invalid question data.'
        redirect_to manage_quiz_path(@quiz)
        return
      rescue StandardError => e
        Rails.logger.error("Error updating questions: #{e.message}")
        flash[:alert] = "Error updating questions: #{e.message}"
        redirect_to manage_quiz_path(@quiz)
        return
      end
    end

    @quiz.assign_attributes(quiz_params)

    unless validate_quiz_time(@quiz)
      flash.now[:alert] = @quiz.errors.full_messages.join(", ")
      set_courses
      return render :edit, status: :unprocessable_entity
    end

    if @quiz.save
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

    redirect_to manage_quizzes_path, notice: 'Quiz was successfully deleted.'
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
      render json: { error: 'Missing required information' }, status: :bad_request
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
        render json: { error: 'Unable to generate questions from this transcription content' }, status: :unprocessable_entity
        return
      end

      render json: questions, status: :ok
    rescue StandardError => e
      Rails.logger.error("Error generating questions from transcription: #{e.message}")
      render json: { error: "Unable to generate questions: #{e.message}" }, status: :unprocessable_entity
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
                                 transcription_value.to_s
                               else
                                 'No transcription available for this video.'
                               end
    else
      result[:transcription] = 'No transcription available for this video.'
    end

    result
  end

  def set_quiz
    @quiz = Quiz.includes(questions: [:quiz_questions]).joins(:course).where(courses: { user_id: current_user.id }).find_by(id: params[:id])

    unless @quiz
      flash[:alert] = "Không tìm thấy bài kiểm tra"
      redirect_to manage_quizzes_path
    end
  end

  def set_courses
    @courses = Course.where(user_id: current_user.id).order(:title)
  end

  def quiz_params
    params.require(:quiz).permit(:title, :is_exam, :time_limit, :course_id, :start_time, :end_time)
  end

  def validate_quiz_time(quiz)
    start_time = quiz.start_time
    end_time = quiz.end_time

    if start_time.present? && end_time.present?
      if start_time >= end_time
        quiz.errors.add(:end_time, "must be after start time")
        return false
      end

      if quiz.time_limit.present?
        time_diff_minutes = ((end_time - start_time) / 60).to_i
        if quiz.time_limit > time_diff_minutes
          quiz.errors.add(:time_limit, "cannot be greater than the time period between start and end times")
          return false
        end
      end
    end

    true
  end
end
