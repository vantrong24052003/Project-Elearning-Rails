# frozen_string_literal: true

require 'test_helper'

class Manage::EnrollmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @enrollment = enrollments(:one)
    @user = users(:admin)
    sign_in @user
  end

  test 'should get index' do
    get manage_enrollments_url
    assert_response :success
  end

  test 'should get new' do
    get new_manage_enrollment_url
    assert_response :success
  end

  test 'should create enrollment' do
    assert_difference('Enrollment.count') do
      post manage_enrollments_url, params: {
        enrollment: {
          user_id: users(:student).id,
          course_id: courses(:one).id,
          status: 'active',
          payment_method: 'bank_transfer',
          amount: 100_000
        }
      }
    end

    assert_redirected_to manage_enrollment_path(Enrollment.last)
  end

  test 'should show enrollment' do
    get manage_enrollment_url(@enrollment)
    assert_response :success
  end

  test 'should get edit' do
    get edit_manage_enrollment_url(@enrollment)
    assert_response :success
  end

  test 'should update enrollment' do
    patch manage_enrollment_url(@enrollment), params: {
      enrollment: {
        status: 'completed'
      }
    }
    assert_redirected_to manage_enrollments_path
  end

  test 'should confirm payment' do
    patch manage_enrollment_url(@enrollment), params: {
      enrollment: {
        paid_at: Time.current
      }
    }
    assert_redirected_to manage_enrollments_path
    assert_equal 'Đã xác nhận thanh toán thành công', flash[:notice]
  end

  test 'should cancel payment confirmation' do
    @enrollment.update(paid_at: Time.current)
    
    patch manage_enrollment_url(@enrollment), params: {
      enrollment: {
        paid_at: nil
      }
    }
    assert_redirected_to manage_enrollments_path
    assert_equal 'Đã hủy xác nhận thanh toán', flash[:notice]
  end

  test 'should destroy enrollment' do
    assert_difference('Enrollment.count', -1) do
      delete manage_enrollment_url(@enrollment)
    end

    assert_redirected_to manage_enrollments_path
  end
end
