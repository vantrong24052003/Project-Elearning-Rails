require 'test_helper'

class Dashboard::PaymentsControllerTest < ActionDispatch::IntegrationTest
  def test_payments_controller_has_all_restful_methods
    controller = Dashboard::PaymentsController.new
    
    assert_respond_to controller, :index
    assert_respond_to controller, :show
    assert_respond_to controller, :new
    assert_respond_to controller, :create
    assert_respond_to controller, :edit
    assert_respond_to controller, :update
    assert_respond_to controller, :destroy
  end

  def test_controller_initializes_payment_service
    controller = Dashboard::PaymentsController.new
    assert_respond_to controller, :send, :initialize_payment_service
  end
end
