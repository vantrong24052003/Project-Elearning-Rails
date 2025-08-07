# frozen_string_literal: true

class Dashboard::ViewerService
  def initialize(current_user)
    @current_user = current_user
  end

  def authorize_course_access(course)
    return true if @current_user&.has_role?(:admin)
    return true if course.user_id == @current_user&.id
    return true if course.enrollments.exists?(user_id: @current_user&.id, status: :active)

    false
  end

  def get_first_lesson_and_video(course)
    first_lesson = course.lessons.order(:position).first
    first_video = first_lesson&.videos&.order(:position)&.first if first_lesson

    return nil, nil unless first_lesson && first_video

    [first_lesson, first_video]
  end

  def get_current_lesson_and_video(course, lesson_id, video_id)
    current_lesson = course.lessons.find_by(id: lesson_id) if lesson_id
    current_video = current_lesson&.videos&.find_by(id: video_id) if video_id

    [current_lesson, current_video]
  end

  def get_course_structure(course)
    {
      lessons: course.lessons.includes(:videos).order(:position),
      total_lessons: course.lessons.count,
      total_videos: course.lessons.joins(:videos).count
    }
  end

  def get_user_progress(course)
    return {} unless @current_user

    video_ids = course.lessons.joins(:videos).pluck('videos.id')

    watched_videos = VideoProgress.where(user: @current_user, video_id: video_ids, watched: true).count

    {
      completed_videos: watched_videos,
      total_videos: video_ids.size,
      enrollment: course.enrollments.find_by(user: @current_user)
    }
  end
end
