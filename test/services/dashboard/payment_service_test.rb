require 'test_helper'

class Dashboard::PaymentServiceTest < Minitest::Test
  def test_payment_service_can_be_initialized
    user = User.new(email: 'test@example.com')
    service = Dashboard::PaymentService.new(user)
    refute_nil service
  end

  def test_payment_service_responds_to_process_payment
    user = User.new(email: 'test@example.com')
    service = Dashboard::PaymentService.new(user)
    assert_respond_to service, :process_payment
  end

  def test_payment_service_responds_to_get_enrollment_info
    user = User.new(email: 'test@example.com')
    service = Dashboard::PaymentService.new(user)
    assert_respond_to service, :get_enrollment_info
  end
end
