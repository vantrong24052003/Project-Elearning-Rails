# frozen_string_literal: true

class Dashboard::PaymentService
  def initialize(current_user)
    @current_user = current_user
  end

  def process_payment(course)
    enrollment = find_or_create_enrollment(course)
    complete_payment(enrollment)
    enrollment
  end

  def get_enrollment_info(course)
    find_or_create_enrollment(course)
  end

  private

  def find_or_create_enrollment(course)
    Enrollment.find_or_create_by(course: course, user: @current_user) do |enrollment|
      enrollment.status = :pending
      enrollment.amount = course.price
      enrollment.payment_code = generate_payment_code
    end
  end

  def complete_payment(enrollment)
    enrollment.update!(
      status: :active,
      payment_method: :credit_card,
      paid_at: Time.current,
      enrolled_at: Time.current
    )
  end

  def generate_payment_code
    SecureRandom.hex(4).upcase
  end
end
