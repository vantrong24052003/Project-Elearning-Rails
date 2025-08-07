# frozen_string_literal: true

require 'test_helper'

class Dashboard::ViewersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:default_user)
    @admin = users(:admin_user)
    @course = courses(:published_course)
    sign_in @user
  end

  test 'viewers controller has all restful methods' do
    controller = Dashboard::ViewersController.new

    assert_respond_to controller, :index
    assert_respond_to controller, :show
    assert_respond_to controller, :new
    assert_respond_to controller, :create
    assert_respond_to controller, :edit
    assert_respond_to controller, :update
    assert_respond_to controller, :destroy
  end

  test 'should get index with enrolled courses' do
    # Create enrollment
    Enrollment.create!(
      user: @user,
      course: @course,
      status: :active,
      payment_code: 'TEST123'
    )

    get dashboard_course_viewers_path(@course)
    assert_response :success
  end

  test 'should get show when user has access' do
    Enrollment.create!(
      user: @user,
      course: @course,
      status: :active,
      payment_code: 'TEST123'
    )

    get dashboard_course_viewer_path(@course, @course)
    assert_response :success
  end

  test 'should redirect when user lacks access to course' do
    get dashboard_course_viewer_path(@course, @course)
    assert_redirected_to dashboard_course_path(@course)
    assert_equal 'You are not authorized to view this course', flash[:alert]
  end

  test 'admin should have access to any course' do
    sign_in @admin
    get dashboard_course_viewer_path(@course, @course)
    assert_response :success
  end

  test 'course owner should have access' do
    @course.update!(user: @user)
    get dashboard_course_viewer_path(@course, @course)
    assert_response :success
  end
end
