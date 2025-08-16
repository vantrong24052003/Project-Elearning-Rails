# frozen_string_literal: true

class Dashboard::PaymentsController < ApplicationController
  include AccountSecurity
  before_action :check_locked_account
  before_action :set_course, only: %i[index create]
  before_action :initialize_payment_service

  def index
    @enrollment = @payment_service.get_enrollment_info(@course)
  end

  def create
    @enrollment = @payment_service.process_payment(@course)
    redirect_to dashboard_course_path(@course), notice: 'Payment successful!'
  end

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
