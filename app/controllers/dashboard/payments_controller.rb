# frozen_string_literal: true

class Dashboard::PaymentsController < Dashboard::DashboardController
  before_action :set_course
  before_action :initialize_payment_service

  def index
    authorize! :view_payment, @course
    @enrollment = @payment_service.get_enrollment_info(@course)
  end

  def show; end

  def new; end

  def create
    authorize! :create_payment, @course
    @enrollment = @payment_service.process_payment(@course)
    redirect_to dashboard_course_path(@course), notice: 'Thanh toán thành công!'
  end

  def edit; end

  def update; end

  def destroy; end

  private

  def set_course
    @course = Course.find_by(id: params[:course_id])
    return unless @course.nil?

    redirect_to dashboard_courses_path, alert: 'Course not found'
  end

  def initialize_payment_service
    @payment_service = Dashboard::PaymentService.new(current_user)
  end
end
