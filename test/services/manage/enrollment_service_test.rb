# frozen_string_literal: true

require 'test_helper'

module Manage
  class EnrollmentServiceTest < ActiveSupport::TestCase
    setup do
      @user = users(:teacher)
      @enrollment_service = Manage::EnrollmentService.new(@user)
      @enrollment = enrollments(:one)
    end

    test 'should filter enrollments' do
      result = @enrollment_service.filter_enrollments({})
      assert_kind_of ActiveRecord::Relation, result
    end

    test 'should create enrollment' do
      enrollment_params = {
        user_id: users(:student).id,
        course_id: courses(:one).id,
        status: 'active',
        payment_method: 'bank_transfer',
        amount: 100_000
      }

      enrollment = @enrollment_service.create_enrollment(enrollment_params)
      assert enrollment.persisted?
    end

    test 'should update enrollment' do
      result = @enrollment_service.update_enrollment(@enrollment, { status: 'completed' })
      assert result[:success]
      assert_equal 'Enrollment was successfully updated', result[:message]
    end

    test 'should confirm payment' do
      result = @enrollment_service.update_enrollment(@enrollment, { paid_at: Time.current })
      assert result[:success]
      assert_equal 'Đã xác nhận thanh toán thành công', result[:message]
    end

    test 'should cancel payment' do
      @enrollment.update(paid_at: Time.current)
      result = @enrollment_service.update_enrollment(@enrollment, { paid_at: nil })
      assert result[:success]
      assert_equal 'Đã hủy xác nhận thanh toán', result[:message]
    end

    test 'should delete enrollment' do
      result = @enrollment_service.delete_enrollment(@enrollment)
      assert result[:success]
      assert_equal 'Enrollment was successfully deleted', result[:message]
    end
  end
end
