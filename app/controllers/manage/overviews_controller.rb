class Manage::OverviewsController < Manage::BaseController
  def index
    @courses = current_user.courses.order(created_at: :desc)
    @selected_course_id = params[:course_id]

    @total_courses = @courses.count
    @total_students = get_total_students
    @completion_rate = calculate_completion_rate
    @average_rating = calculate_average_rating

    @active_courses = @courses.where(status: :published).count
    @pending_courses = @courses.where(status: :draft).count

    @new_students = get_new_students
    @students_by_course = get_students_by_course

    @total_videos = get_total_videos
    @pending_videos = get_pending_videos
    @rejected_videos = get_rejected_videos

    @total_quizzes = get_total_quizzes
    @average_quiz_score = get_average_quiz_score
    @quiz_completion_rate = calculate_quiz_completion_rate
  end

  private

  def get_total_students
    query = Enrollment.joins(:course)
                     .where(courses: { user_id: current_user.id })
    query = query.where(course_id: @selected_course_id) if @selected_course_id.present?
    query.distinct.count(:user_id)
  end

  def calculate_completion_rate
    query = Enrollment.joins(:course)
                     .where(courses: { user_id: current_user.id })
    query = query.where(course_id: @selected_course_id) if @selected_course_id.present?

    total_enrollments = query.count
    completed_enrollments = query.where.not(completed_at: nil).count

    total_enrollments.positive? ? (completed_enrollments.to_f / total_enrollments * 100).round : 0
  end

  def calculate_average_rating
    query = @courses
    query = query.where(id: @selected_course_id) if @selected_course_id.present?
    query.average(:rating)&.round(2) || 0
  end

  def get_new_students
    query = Enrollment.joins(:course)
                     .where(courses: { user_id: current_user.id })
                     .where('enrollments.created_at >= ?', 30.days.ago)
    query = query.where(course_id: @selected_course_id) if @selected_course_id.present?
    query.distinct.count(:user_id)
  end

  def get_students_by_course
    courses = current_user.courses
    courses = courses.where(id: @selected_course_id) if @selected_course_id.present?

    courses.includes(:enrollments).map do |course|
      enrollments = course.enrollments
      total_students = enrollments.distinct.count(:user_id)

      new_students = enrollments
                    .where('enrollments.created_at >= ?', 30.days.ago)
                    .distinct
                    .count(:user_id)

      completed = enrollments.where.not(completed_at: nil).count
      completion_rate = total_students.positive? ? (completed.to_f / total_students * 100).round : 0

      {
        title: course.title,
        student_count: total_students,
        new_students_count: new_students,
        completion_rate: completion_rate
      }
    end.sort_by { |c| -c[:student_count] }
  end

  def get_total_videos
    query = Video.joins(lesson: { chapter: :course })
                .where(courses: { user_id: current_user.id })
    query = query.where(courses: { id: @selected_course_id }) if @selected_course_id.present?
    query.count
  end

  def get_pending_videos
    query = Video.joins(lesson: { chapter: :course })
                .where(courses: { user_id: current_user.id })
                .where(moderation_status: 'pending')
    query = query.where(courses: { id: @selected_course_id }) if @selected_course_id.present?
    query.count
  end

  def get_rejected_videos
    query = Video.joins(lesson: { chapter: :course })
                .where(courses: { user_id: current_user.id })
                .where(moderation_status: 'rejected')
    query = query.where(courses: { id: @selected_course_id }) if @selected_course_id.present?
    query.count
  end

  def get_total_quizzes
    query = Quiz.joins(:course)
                .where(courses: { user_id: current_user.id })
    query = query.where(course_id: @selected_course_id) if @selected_course_id.present?
    query.count
  end

  def get_average_quiz_score
    query = QuizAttempt.joins(quiz: :course)
                      .where(courses: { user_id: current_user.id })
    query = query.where(courses: { id: @selected_course_id }) if @selected_course_id.present?
    query.average(:score)&.round(1) || 0
  end

  def calculate_quiz_completion_rate
    query = Quiz.joins(:course)
                .where(courses: { user_id: current_user.id })
    query = query.where(course_id: @selected_course_id) if @selected_course_id.present?

    total_quizzes = query.count
    return 0 if total_quizzes.zero?

    completed_quizzes = QuizAttempt.joins(quiz: :course)
                                  .where(courses: { user_id: current_user.id })
    completed_quizzes = completed_quizzes.where(courses: { id: @selected_course_id }) if @selected_course_id.present?
    completed_quizzes = completed_quizzes.distinct.count(:quiz_id)

    (completed_quizzes.to_f / total_quizzes * 100).round
  end
end
