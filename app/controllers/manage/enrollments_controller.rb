# frozen_string_literal: true

class Manage::EnrollmentsController < Manage::BaseController
  before_action :set_enrollment, only: %i[show edit update destroy]

  def index
    @enrollments = Enrollment.includes(:user, :course)
    @enrollments = @enrollments.joins(:course).where(courses: { user_id: current_user.id })
    if params[:search].present?
      @enrollments = @enrollments.where('payment_code ILIKE ? OR users.name ILIKE ? OR courses.title ILIKE ?',
                                        "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%")
    end
    @enrollments = @enrollments.where(status: params[:status]) if params[:status].present?
    @enrollments = @enrollments.where(payment_method: params[:payment_method]) if params[:payment_method].present?
    @enrollments = @enrollments.where('paid_at IS NOT NULL') if params[:paid_at] == 'paid'
    @enrollments = @enrollments.where(paid_at: nil) if params[:paid_at] == 'unpaid'

    @enrollments = @enrollments.page(params[:page]).per(params[:per_page] || 10)
  end

  def show; end

  def new
    @enrollment = Enrollment.new
  end

  def create
    @enrollment = Enrollment.new(enrollment_params)

    if @enrollment.save
      redirect_to manage_enrollment_path(@enrollment), notice: 'Enrollment was successfully created'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @enrollment.update(enrollment_params)
      if params[:enrollment][:paid_at].present?
        redirect_to manage_enrollments_path, notice: 'Đã xác nhận thanh toán thành công'
      elsif params[:enrollment][:paid_at].nil?
        redirect_to manage_enrollments_path, notice: 'Đã hủy xác nhận thanh toán'
      else
        redirect_to manage_enrollments_path, notice: 'Enrollment was successfully updated'
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @enrollment.destroy
    redirect_to manage_enrollments_path, notice: 'Enrollment was successfully deleted'
  end

  private

  def set_enrollment
    @enrollment = Enrollment.find(params[:id])
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
