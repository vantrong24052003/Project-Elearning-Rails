# frozen_string_literal: true

class Manage::EnrollmentService
    def initialize(current_user)
      @current_user = current_user
    end

    def filter_enrollments(params)
      enrollments = Enrollment.includes(:user, :course)
      enrollments = enrollments.joins(:course).where(courses: { user_id: @current_user.id })

      if params[:search].present?
        enrollments = enrollments.where('payment_code ILIKE ? OR users.name ILIKE ? OR courses.title ILIKE ?',
                                        "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%")
      end

      enrollments = enrollments.where(status: params[:status]) if params[:status].present?

      enrollments = enrollments.where(payment_method: params[:payment_method]) if params[:payment_method].present?

      enrollments = enrollments.where('paid_at IS NOT NULL') if params[:paid_at] == 'paid'
      enrollments = enrollments.where(paid_at: nil) if params[:paid_at] == 'unpaid'

      enrollments.page(params[:page]).per(params[:per_page] || 10)
    end

    def create_enrollment(enrollment_params)
      enrollment = Enrollment.new(enrollment_params)
      enrollment.save
      enrollment
    end

    def update_enrollment(enrollment, enrollment_params)
      enrollment.update(enrollment_params)

      if enrollment.saved_change_to_paid_at?
        if enrollment.paid_at.present?
          { success: true, message: 'Đã xác nhận thanh toán thành công' }
        else
          { success: true, message: 'Đã hủy xác nhận thanh toán' }
        end
      else
        { success: true, message: 'Enrollment was successfully updated' }
      end
    end

    def delete_enrollment(enrollment)
      enrollment.destroy
      { success: true, message: 'Enrollment was successfully deleted' }
    end
end
