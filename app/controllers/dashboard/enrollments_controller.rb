# frozen_string_literal: true

class Dashboard::EnrollmentsController < Dashboard::DashboardController
  before_action :authenticate_user!
  before_action :set_course, only: [:create]
  before_action :check_enrollment, only: [:create]

  def create
    @enrollment = current_user.enrollments.new(
      course: @course,
      status: :active,
      enrolled_at: Time.current
    )

    if @enrollment.save
      current_user.cart_items.find_by(course_id: @course.id)&.destroy

      respond_to do |format|
        format.html { redirect_to course_viewer_dashboard_course_path(@course), notice: 'Đăng ký khóa học thành công' }
        format.turbo_stream { flash.now[:notice] = 'Đăng ký khóa học thành công' }
      end
    else
      respond_to do |format|
        format.html { redirect_to dashboard_course_path(@course), alert: 'Không thể đăng ký khóa học' }
        format.turbo_stream { flash.now[:alert] = 'Không thể đăng ký khóa học' }
      end
    end
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def check_enrollment
    if current_user.enrollments.exists?(course: @course)
      redirect_to course_viewer_dashboard_course_path(@course), notice: 'Bạn đã đăng ký khóa học này rồi'
      return false
    end
  end
end
