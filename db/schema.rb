# frozen_string_literal: true

# frozen_string_literal: true

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 20_250_513_084_528) do
ActiveRecord::Schema[8.0].define(version: 20_250_513_084_528) do
  # These are extensions that must be enabled in order to support this database
  enable_extension 'pg_catalog.plpgsql'
  enable_extension 'pgcrypto'
  enable_extension 'pg_catalog.plpgsql'
  enable_extension 'pgcrypto'

  create_table 'categories', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
    t.string 'name'
    t.text 'description'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  create_table 'categories', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
    t.string 'name'
    t.text 'description'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end

  create_table 'chapters', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
    t.string 'title'
    t.integer 'position'
    t.uuid 'course_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['course_id'], name: 'index_chapters_on_course_id'
  create_table 'chapters', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
    t.string 'title'
    t.integer 'position'
    t.uuid 'course_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['course_id'], name: 'index_chapters_on_course_id'
  end

  create_table 'course_categories', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
    t.uuid 'course_id', null: false
    t.uuid 'category_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['category_id'], name: 'index_course_categories_on_category_id'
    t.index ['course_id'], name: 'index_course_categories_on_course_id'
  create_table 'course_categories', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
    t.uuid 'course_id', null: false
    t.uuid 'category_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['category_id'], name: 'index_course_categories_on_category_id'
    t.index ['course_id'], name: 'index_course_categories_on_course_id'
  end

  create_table 'courses', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
    t.string 'title'
    t.text 'description'
    t.decimal 'price'
    t.string 'thumbnail_path'
    t.string 'language'
    t.string 'status'
    t.string 'demo_video_path'
    t.uuid 'user_id', null: false
    t.uuid 'category_id', null: false
    t.boolean 'is_free', default: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.decimal 'rating', precision: 3, scale: 2, default: '0.0'
    t.index ['category_id'], name: 'index_courses_on_category_id'
    t.index ['user_id'], name: 'index_courses_on_user_id'
  create_table 'courses', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
    t.string 'title'
    t.text 'description'
    t.decimal 'price'
    t.string 'thumbnail_path'
    t.string 'language'
    t.string 'status'
    t.string 'demo_video_path'
    t.uuid 'user_id', null: false
    t.uuid 'category_id', null: false
    t.boolean 'is_free', default: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.decimal 'rating', precision: 3, scale: 2, default: '0.0'
    t.index ['category_id'], name: 'index_courses_on_category_id'
    t.index ['user_id'], name: 'index_courses_on_user_id'
  end

  create_table 'enrollments', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
    t.uuid 'user_id', null: false
    t.uuid 'course_id', null: false
    t.string 'status', default: 'pending'
    t.string 'payment_code'
    t.string 'payment_method'
    t.decimal 'amount', precision: 10, scale: 2
    t.datetime 'paid_at'
    t.datetime 'enrolled_at'
    t.datetime 'completed_at'
    t.string 'note'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['course_id'], name: 'index_enrollments_on_course_id'
    t.index ['payment_code'], name: 'index_enrollments_on_payment_code', unique: true
    t.index %w[user_id course_id], name: 'index_enrollments_on_user_id_and_course_id', unique: true
    t.index ['user_id'], name: 'index_enrollments_on_user_id'
  create_table 'enrollments', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
    t.uuid 'user_id', null: false
    t.uuid 'course_id', null: false
    t.string 'status', default: 'pending'
    t.string 'payment_code'
    t.string 'payment_method'
    t.decimal 'amount', precision: 10, scale: 2
    t.datetime 'paid_at'
    t.datetime 'enrolled_at'
    t.datetime 'completed_at'
    t.string 'note'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['course_id'], name: 'index_enrollments_on_course_id'
    t.index ['payment_code'], name: 'index_enrollments_on_payment_code', unique: true
    t.index %w[user_id course_id], name: 'index_enrollments_on_user_id_and_course_id', unique: true
    t.index ['user_id'], name: 'index_enrollments_on_user_id'
  end

  create_table 'lessons', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
    t.string 'title'
    t.text 'description'
    t.integer 'position'
    t.uuid 'chapter_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['chapter_id'], name: 'index_lessons_on_chapter_id'
  create_table 'lessons', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
    t.string 'title'
    t.text 'description'
    t.integer 'position'
    t.uuid 'chapter_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['chapter_id'], name: 'index_lessons_on_chapter_id'
  end

  create_table 'progresses', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
    t.string 'status'
    t.uuid 'user_id', null: false
    t.uuid 'course_id', null: false
    t.uuid 'lesson_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['course_id'], name: 'index_progresses_on_course_id'
    t.index ['lesson_id'], name: 'index_progresses_on_lesson_id'
    t.index ['user_id'], name: 'index_progresses_on_user_id'
  create_table 'progresses', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
    t.string 'status'
    t.uuid 'user_id', null: false
    t.uuid 'course_id', null: false
    t.uuid 'lesson_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['course_id'], name: 'index_progresses_on_course_id'
    t.index ['lesson_id'], name: 'index_progresses_on_lesson_id'
    t.index ['user_id'], name: 'index_progresses_on_user_id'
  end

  create_table 'questions', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
    t.text 'content'
    t.json 'options'
    t.integer 'correct_option'
    t.text 'explanation'
    t.string 'difficulty'
    t.uuid 'course_id', null: false
    t.uuid 'user_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['course_id'], name: 'index_questions_on_course_id'
    t.index ['user_id'], name: 'index_questions_on_user_id'
  create_table 'questions', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
    t.text 'content'
    t.json 'options'
    t.integer 'correct_option'
    t.text 'explanation'
    t.string 'difficulty'
    t.uuid 'course_id', null: false
    t.uuid 'user_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['course_id'], name: 'index_questions_on_course_id'
    t.index ['user_id'], name: 'index_questions_on_user_id'
  end

  create_table 'quiz_attempts', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
    t.decimal 'score'
    t.uuid 'quiz_id', null: false
    t.uuid 'user_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.text 'answers'
    t.integer 'time_spent'
    t.datetime 'start_time'
    t.datetime 'completed_at'
    t.integer 'tab_switch_count', default: 0
    t.integer 'copy_paste_count', default: 0
    t.integer 'screenshot_count', default: 0
    t.integer 'right_click_count', default: 0
    t.integer 'devtools_open_count', default: 0
    t.integer 'other_unusual_actions', default: 0
    t.integer 'device_count', default: 1
    t.datetime 'notified_at'
    t.jsonb 'log_actions', default: [], null: false
    t.index ['quiz_id'], name: 'index_quiz_attempts_on_quiz_id'
    t.index ['user_id'], name: 'index_quiz_attempts_on_user_id'
  end

  create_table 'quiz_questions', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
    t.uuid 'quiz_id', null: false
    t.uuid 'question_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['question_id'], name: 'index_quiz_questions_on_question_id'
    t.index ['quiz_id'], name: 'index_quiz_questions_on_quiz_id'
  create_table 'quiz_questions', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
    t.uuid 'quiz_id', null: false
    t.uuid 'question_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['question_id'], name: 'index_quiz_questions_on_question_id'
    t.index ['quiz_id'], name: 'index_quiz_questions_on_quiz_id'
  end

  create_table 'quizzes', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
    t.string 'title'
    t.boolean 'is_exam'
    t.integer 'time_limit'
    t.uuid 'course_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.datetime 'start_time'
    t.datetime 'end_time'
    t.boolean 'notify_cheating', default: true
    t.index ['course_id'], name: 'index_quizzes_on_course_id'
  create_table 'quizzes', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
    t.string 'title'
    t.boolean 'is_exam'
    t.integer 'time_limit'
    t.uuid 'course_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.datetime 'start_time'
    t.datetime 'end_time'
    t.boolean 'notify_cheating', default: true
    t.index ['course_id'], name: 'index_quizzes_on_course_id'
  end

  create_table 'roles', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
    t.string 'name'
    t.string 'resource_type'
    t.uuid 'resource_id'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index %w[name resource_type resource_id], name: 'index_roles_on_name_and_resource_type_and_resource_id',
                                                unique: true
    t.index ['name'], name: 'index_roles_on_name'
    t.index %w[resource_type resource_id], name: 'index_roles_on_resource'
  create_table 'roles', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
    t.string 'name'
    t.string 'resource_type'
    t.uuid 'resource_id'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index %w[name resource_type resource_id], name: 'index_roles_on_name_and_resource_type_and_resource_id',
                                                unique: true
    t.index ['name'], name: 'index_roles_on_name'
    t.index %w[resource_type resource_id], name: 'index_roles_on_resource'
  end

  create_table 'uploads', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
    t.string 'file_type'
    t.string 'cdn_url'
    t.string 'thumbnail_path'
    t.integer 'duration'
    t.string 'status'
    t.uuid 'user_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.string 'formats', default: [], array: true
    t.integer 'progress', default: 0
    t.text 'processing_log'
    t.string 'quality_360p_url'
    t.string 'quality_480p_url'
    t.string 'quality_720p_url'
    t.index ['user_id'], name: 'index_uploads_on_user_id'
  create_table 'uploads', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
    t.string 'file_type'
    t.string 'cdn_url'
    t.string 'thumbnail_path'
    t.integer 'duration'
    t.string 'status'
    t.uuid 'user_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.string 'formats', default: [], array: true
    t.integer 'progress', default: 0
    t.text 'processing_log'
    t.string 'quality_360p_url'
    t.string 'quality_480p_url'
    t.string 'quality_720p_url'
    t.index ['user_id'], name: 'index_uploads_on_user_id'
  end

  create_table 'users', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
    t.string 'email', default: '', null: false
    t.string 'encrypted_password', default: '', null: false
    t.string 'reset_password_token'
    t.datetime 'reset_password_sent_at'
    t.datetime 'remember_created_at'
    t.integer 'sign_in_count', default: 0, null: false
    t.datetime 'current_sign_in_at'
    t.datetime 'last_sign_in_at'
    t.string 'current_sign_in_ip'
    t.string 'last_sign_in_ip'
    t.string 'confirmation_token'
    t.datetime 'confirmed_at'
    t.datetime 'confirmation_sent_at'
    t.string 'unconfirmed_email'
    t.integer 'failed_attempts', default: 0, null: false
    t.string 'unlock_token'
    t.datetime 'locked_at'
    t.string 'phone'
    t.string 'address'
    t.string 'name'
    t.string 'avatar'
    t.text 'bio'
    t.date 'date_of_birth'
    t.string 'instructor_request_status'
    t.datetime 'instructor_requested_at'
    t.datetime 'instructor_reviewed_at'
    t.index ['confirmation_token'], name: 'index_users_on_confirmation_token', unique: true
    t.index ['email'], name: 'index_users_on_email', unique: true
    t.index ['instructor_request_status'], name: 'index_users_on_instructor_request_status'
    t.index ['reset_password_token'], name: 'index_users_on_reset_password_token', unique: true
    t.index ['unlock_token'], name: 'index_users_on_unlock_token', unique: true
  create_table 'users', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
    t.string 'email', default: '', null: false
    t.string 'encrypted_password', default: '', null: false
    t.string 'reset_password_token'
    t.datetime 'reset_password_sent_at'
    t.datetime 'remember_created_at'
    t.integer 'sign_in_count', default: 0, null: false
    t.datetime 'current_sign_in_at'
    t.datetime 'last_sign_in_at'
    t.string 'current_sign_in_ip'
    t.string 'last_sign_in_ip'
    t.string 'confirmation_token'
    t.datetime 'confirmed_at'
    t.datetime 'confirmation_sent_at'
    t.string 'unconfirmed_email'
    t.integer 'failed_attempts', default: 0, null: false
    t.string 'unlock_token'
    t.datetime 'locked_at'
    t.string 'phone'
    t.string 'address'
    t.string 'name'
    t.string 'avatar'
    t.text 'bio'
    t.date 'date_of_birth'
    t.string 'instructor_request_status'
    t.datetime 'instructor_requested_at'
    t.datetime 'instructor_reviewed_at'
    t.index ['confirmation_token'], name: 'index_users_on_confirmation_token', unique: true
    t.index ['email'], name: 'index_users_on_email', unique: true
    t.index ['instructor_request_status'], name: 'index_users_on_instructor_request_status'
    t.index ['reset_password_token'], name: 'index_users_on_reset_password_token', unique: true
    t.index ['unlock_token'], name: 'index_users_on_unlock_token', unique: true
  end

  create_table 'users_roles', id: false, force: :cascade do |t|
    t.uuid 'user_id', null: false
    t.uuid 'role_id', null: false
    t.index ['role_id'], name: 'index_users_roles_on_role_id'
    t.index %w[user_id role_id], name: 'index_users_roles_on_user_id_and_role_id', unique: true
    t.index ['user_id'], name: 'index_users_roles_on_user_id'
  create_table 'users_roles', id: false, force: :cascade do |t|
    t.uuid 'user_id', null: false
    t.uuid 'role_id', null: false
    t.index ['role_id'], name: 'index_users_roles_on_role_id'
    t.index %w[user_id role_id], name: 'index_users_roles_on_user_id_and_role_id', unique: true
    t.index ['user_id'], name: 'index_users_roles_on_user_id'
  end

  create_table 'video_progresses', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
    t.uuid 'user_id', null: false
    t.uuid 'video_id', null: false
    t.boolean 'watched'
    t.datetime 'watched_at'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['user_id'], name: 'index_video_progresses_on_user_id'
    t.index ['video_id'], name: 'index_video_progresses_on_video_id'
  create_table 'video_progresses', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
    t.uuid 'user_id', null: false
    t.uuid 'video_id', null: false
    t.boolean 'watched'
    t.datetime 'watched_at'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['user_id'], name: 'index_video_progresses_on_user_id'
    t.index ['video_id'], name: 'index_video_progresses_on_video_id'
  end

  create_table 'videos', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
    t.string 'title'
    t.date 'is_locked'
    t.uuid 'lesson_id', null: false
    t.uuid 'upload_id', null: false
    t.string 'moderation_status', default: 'pending'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.string 'thumbnail'
    t.integer 'position'
    t.index ['lesson_id'], name: 'index_videos_on_lesson_id'
    t.index ['upload_id'], name: 'index_videos_on_upload_id'
  create_table 'videos', id: :uuid, default: -> { 'gen_random_uuid()' }, force: :cascade do |t|
    t.string 'title'
    t.date 'is_locked'
    t.uuid 'lesson_id', null: false
    t.uuid 'upload_id', null: false
    t.string 'moderation_status', default: 'pending'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.string 'thumbnail'
    t.integer 'position'
    t.index ['lesson_id'], name: 'index_videos_on_lesson_id'
    t.index ['upload_id'], name: 'index_videos_on_upload_id'
  end

  add_foreign_key 'chapters', 'courses'
  add_foreign_key 'course_categories', 'categories'
  add_foreign_key 'course_categories', 'courses'
  add_foreign_key 'courses', 'categories'
  add_foreign_key 'courses', 'users'
  add_foreign_key 'enrollments', 'courses'
  add_foreign_key 'enrollments', 'users'
  add_foreign_key 'lessons', 'chapters'
  add_foreign_key 'progresses', 'courses'
  add_foreign_key 'progresses', 'lessons'
  add_foreign_key 'progresses', 'users'
  add_foreign_key 'questions', 'courses'
  add_foreign_key 'questions', 'users'
  add_foreign_key 'quiz_attempts', 'quizzes'
  add_foreign_key 'quiz_attempts', 'users'
  add_foreign_key 'quiz_questions', 'questions'
  add_foreign_key 'quiz_questions', 'quizzes'
  add_foreign_key 'quizzes', 'courses'
  add_foreign_key 'uploads', 'users'
  add_foreign_key 'users_roles', 'roles'
  add_foreign_key 'users_roles', 'users'
  add_foreign_key 'video_progresses', 'users'
  add_foreign_key 'video_progresses', 'videos'
  add_foreign_key 'videos', 'lessons'
  add_foreign_key 'videos', 'uploads'
  add_foreign_key 'chapters', 'courses'
  add_foreign_key 'course_categories', 'categories'
  add_foreign_key 'course_categories', 'courses'
  add_foreign_key 'courses', 'categories'
  add_foreign_key 'courses', 'users'
  add_foreign_key 'enrollments', 'courses'
  add_foreign_key 'enrollments', 'users'
  add_foreign_key 'lessons', 'chapters'
  add_foreign_key 'progresses', 'courses'
  add_foreign_key 'progresses', 'lessons'
  add_foreign_key 'progresses', 'users'
  add_foreign_key 'questions', 'courses'
  add_foreign_key 'questions', 'users'
  add_foreign_key 'quiz_attempts', 'quizzes'
  add_foreign_key 'quiz_attempts', 'users'
  add_foreign_key 'quiz_questions', 'questions'
  add_foreign_key 'quiz_questions', 'quizzes'
  add_foreign_key 'quizzes', 'courses'
  add_foreign_key 'uploads', 'users'
  add_foreign_key 'users_roles', 'roles'
  add_foreign_key 'users_roles', 'users'
  add_foreign_key 'video_progresses', 'users'
  add_foreign_key 'video_progresses', 'videos'
  add_foreign_key 'videos', 'lessons'
  add_foreign_key 'videos', 'uploads'
end
