# frozen_string_literal: true

require 'test_helper'

class Dashboard::ViewerServiceTest < ActiveSupport::TestCase
  def setup
    @user = users(:default_user)
    @admin = users(:admin_user)
    @course = courses(:published_course)
    @service = Dashboard::ViewerService.new(@user)
  end

  test 'viewer service can be initialized' do
    refute_nil @service
  end

  test 'get_enrolled_courses returns enrolled courses for user' do
    # Create active enrollment
    Enrollment.create!(
      user: @user,
      course: @course,
      status: :active,
      payment_code: 'TEST123'
    )

    enrolled_courses = @service.get_enrolled_courses
    assert_includes enrolled_courses, @course
  end

  test 'get_enrolled_courses returns empty array for user without enrollments' do
    user_without_enrollments = User.create!(
      email: 'test_viewer@example.com',
      password: 'password',
      first_name: 'Test',
      last_name: 'User'
    )
    service = Dashboard::ViewerService.new(user_without_enrollments)

    enrolled_courses = service.get_enrolled_courses
    assert_empty enrolled_courses
  end

  test 'authorize_course_access returns true for admin' do
    admin_service = Dashboard::ViewerService.new(@admin)
    assert admin_service.authorize_course_access(@course)
  end

  test 'authorize_course_access returns true for course owner' do
    @course.update!(user: @user)
    assert @service.authorize_course_access(@course)
  end

  test 'authorize_course_access returns true for enrolled user' do
    Enrollment.create!(
      user: @user,
      course: @course,
      status: :active,
      payment_code: 'TEST123'
    )

    assert @service.authorize_course_access(@course)
  end

  test 'authorize_course_access returns false for unauthorized user' do
    refute @service.authorize_course_access(@course)
  end

  test 'get_course_structure returns course structure data' do
    structure = @service.get_course_structure(@course)

    assert_includes structure.keys, :lessons
    assert_includes structure.keys, :total_lessons
    assert_includes structure.keys, :total_videos
    assert_equal @course.lessons.count, structure[:total_lessons]
  end

  test 'get_user_progress returns progress data for authenticated user' do
    progress = @service.get_user_progress(@course)

    assert_includes progress.keys, :completed_videos
    assert_includes progress.keys, :total_videos
    assert_includes progress.keys, :enrollment
  end
end
