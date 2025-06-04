# frozen_string_literal: true

class Manage::EnrollmentsController < Manage::BaseController
  before_action :set_enrollment, only: %i[show edit update destroy]
  before_action :initialize_enrollment_service

  def index
    @enrollments = @enrollment_service.filter_enrollments(params)
  end

  def show; end

  def new
    @enrollment = Enrollment.new
  end

  def create
    @enrollment = @enrollment_service.create_enrollment(enrollment_params)

    if @enrollment.persisted?
      redirect_to manage_enrollment_path(@enrollment), notice: 'Enrollment was successfully created'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    result = @enrollment_service.update_enrollment(@enrollment, enrollment_params)

    if result[:success]
      redirect_to manage_enrollments_path, notice: result[:message]
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    result = @enrollment_service.delete_enrollment(@enrollment)
    redirect_to manage_enrollments_path, notice: result[:message]
  end

  private

  def set_enrollment
    @enrollment = Enrollment.find(params[:id])
  end

  def initialize_enrollment_service
    @enrollment_service = Manage::EnrollmentService.new(current_user)
  end

  def enrollment_params
    params.require(:enrollment).permit(
      :user_id,
      :course_id,
      :status,
      :payment_code,
      :payment_method,
      :amount,
      :paid_at,
      :enrolled_at,
      :completed_at,
      :note
    )
  end
end
