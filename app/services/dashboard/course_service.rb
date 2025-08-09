# frozen_string_literal: true

class Dashboard::CourseService
  def filter_courses(params)
    Course.published
          .search_title(params[:search])
          .in_category(params[:category_id])
          .price_min(params[:min_price])
          .price_max(params[:max_price])
          .sorted_by(params[:sort_by])
  end

  def calculate_course_statistics(videos)
    total_duration = 0
    videos.each do |video|
      total_duration += video.upload.duration if video.upload&.duration
    end
    total_duration
  end

  def get_related_courses(course)
    Course.published
          .joins(:course_categories)
          .where(course_categories: { category_id: course.category_ids })
          .where.not(id: course.id)
          .group('courses.id')
          .order(Arel.sql('RANDOM()'))
          .limit(3)
  end
end
