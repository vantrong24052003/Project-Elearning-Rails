# frozen_string_literal: true

class Dashboard::PaymentsController < Dashboard::DashboardController
  before_action :set_course

  def create
    authorize! :create_payment, @course
    @enrollment = Enrollment.find_or_create_by(course: @course, user: current_user) do |enrollment|
      enrollment.status = :pending
      enrollment.amount = @course.price
      enrollment.payment_code = SecureRandom.hex(4).upcase
    end

    @enrollment.update!(
      status: :active,
      payment_method: :credit_card,
      paid_at: Time.current,
      enrolled_at: Time.current
    )

    redirect_to dashboard_course_path(@course), notice: 'Thanh toán thành công!'
  end

  def index
    authorize! :view_payment, @course
    @enrollment = Enrollment.find_or_create_by(course: @course, user: current_user) do |enrollment|
      enrollment.status = :pending
      enrollment.amount = @course.price
      enrollment.payment_code = SecureRandom.hex(4).upcase
    end
  end

  private

  def set_course
    @course = Course.find_by(id: params[:course_id])
    return unless @course.nil?

    redirect_to dashboard_courses_path, alert: 'Course not found'
  end
end
