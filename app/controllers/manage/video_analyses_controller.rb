# frozen_string_literal: true

class Manage::VideoAnalysesController < Manage::BaseController
  before_action :set_video

  def create
    if @video.upload&.transcription.blank?
      render json: { error: 'Video này chưa có bản ghi âm (transcription)' }, status: :bad_request
      return
    end

    if @video.upload&.duration.blank?
      render json: { error: 'Video này chưa có thông tin về thời lượng' }, status: :bad_request
      return
    end

    course = @video.lesson&.chapter&.course

    if course.blank?
      render json: { error: 'Không tìm thấy thông tin khóa học' }, status: :bad_request
      return
    end

    course_overview = {
      title: course.title,
      description: course.description,
      language: course.language,
      rating: course.rating.to_s,
      is_free: course.is_free,
      price: course.price.to_s,
      category_name: course.categories.first&.name
    }

    result = GeminiServices.new.analyze_and_improve_video_lesson(
      title: @video.title,
      transcription: @video.upload.transcription,
      duration: @video.upload.duration,
      course_overview: course_overview
    )

    render json: result
  rescue StandardError => e
    render json: { error: "Đã xảy ra lỗi: #{e.message}" }, status: :internal_server_error
  end

  private

  def set_video
    @video = Video.includes(lesson: { chapter: :course }, upload: :user).find(params[:video_id])
  end
end
