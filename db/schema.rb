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

ActiveRecord::Schema[8.0].define(version: 20_250_420_170_539) do
  # These are extensions that must be enabled in order to support this database
  enable_extension 'pg_catalog.plpgsql'

  create_table 'categories', force: :cascade do |t|
    t.string 'name'
    t.text 'description'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end

  create_table 'chapters', force: :cascade do |t|
    t.string 'title'
    t.integer 'position'
    t.bigint 'course_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['course_id'], name: 'index_chapters_on_course_id'
  end

  create_table 'course_categories', force: :cascade do |t|
    t.bigint 'course_id', null: false
    t.bigint 'category_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['category_id'], name: 'index_course_categories_on_category_id'
    t.index ['course_id'], name: 'index_course_categories_on_course_id'
  end

  create_table 'courses', force: :cascade do |t|
    t.string 'title'
    t.text 'description'
    t.decimal 'price'
    t.string 'thumbnail_path'
    t.string 'language'
    t.string 'status'
    t.bigint 'user_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['user_id'], name: 'index_courses_on_user_id'
  end

  create_table 'lessons', force: :cascade do |t|
    t.string 'title'
    t.text 'description'
    t.integer 'position'
    t.bigint 'chapter_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['chapter_id'], name: 'index_lessons_on_chapter_id'
  end

  create_table 'progresses', force: :cascade do |t|
    t.string 'status'
    t.bigint 'user_id', null: false
    t.bigint 'course_id', null: false
    t.bigint 'lesson_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['course_id'], name: 'index_progresses_on_course_id'
    t.index ['lesson_id'], name: 'index_progresses_on_lesson_id'
    t.index ['user_id'], name: 'index_progresses_on_user_id'
  end

  create_table 'questions', force: :cascade do |t|
    t.text 'content'
    t.json 'options'
    t.integer 'correct_option'
    t.text 'explanation'
    t.string 'difficulty'
    t.bigint 'course_id', null: false
    t.bigint 'user_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['course_id'], name: 'index_questions_on_course_id'
    t.index ['user_id'], name: 'index_questions_on_user_id'
  end

  create_table 'quiz_attempts', force: :cascade do |t|
    t.decimal 'score'
    t.bigint 'quiz_id', null: false
    t.bigint 'user_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['quiz_id'], name: 'index_quiz_attempts_on_quiz_id'
    t.index ['user_id'], name: 'index_quiz_attempts_on_user_id'
  end

  create_table 'quiz_questions', force: :cascade do |t|
    t.bigint 'quiz_id', null: false
    t.bigint 'question_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['question_id'], name: 'index_quiz_questions_on_question_id'
    t.index ['quiz_id'], name: 'index_quiz_questions_on_quiz_id'
  end

  create_table 'quizzes', force: :cascade do |t|
    t.string 'title'
    t.boolean 'is_exam'
    t.integer 'time_limit'
    t.bigint 'course_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['course_id'], name: 'index_quizzes_on_course_id'
  end

  create_table 'roles', force: :cascade do |t|
    t.string 'name'
    t.string 'resource_type'
    t.bigint 'resource_id'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index %w[name resource_type resource_id], name: 'index_roles_on_name_and_resource_type_and_resource_id'
    t.index %w[resource_type resource_id], name: 'index_roles_on_resource'
  end

  create_table 'uploads', force: :cascade do |t|
    t.string 'file_type'
    t.string 'cdn_url'
    t.string 'thumbnail_path'
    t.integer 'duration'
    t.string 'resolution'
    t.string 'status'
    t.bigint 'user_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['user_id'], name: 'index_uploads_on_user_id'
  end

  create_table 'users', force: :cascade do |t|
    t.string 'email', default: '', null: false
    t.string 'encrypted_password', default: '', null: false
    t.string 'reset_password_token'
    t.datetime 'reset_password_sent_at'
    t.datetime 'remember_created_at'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.string 'phone'
    t.string 'address'
    t.string 'name'
    t.string 'avatar'
    t.text 'bio'
    t.date 'date_of_birth'
    t.string 'confirmation_token'
    t.datetime 'confirmed_at'
    t.datetime 'confirmation_sent_at'
    t.string 'unconfirmed_email'
    t.string 'instructor_request_status'
    t.datetime 'instructor_requested_at'
    t.datetime 'instructor_reviewed_at'
    t.integer 'failed_attempts', default: 0, null: false
    t.string 'unlock_token'
    t.datetime 'locked_at'
    t.integer 'sign_in_count', default: 0, null: false
    t.datetime 'current_sign_in_at'
    t.datetime 'last_sign_in_at'
    t.string 'current_sign_in_ip'
    t.string 'last_sign_in_ip'
    t.index ['confirmation_token'], name: 'index_users_on_confirmation_token', unique: true
    t.index ['email'], name: 'index_users_on_email', unique: true
    t.index ['instructor_request_status'], name: 'index_users_on_instructor_request_status'
    t.index ['reset_password_token'], name: 'index_users_on_reset_password_token', unique: true
    t.index ['unlock_token'], name: 'index_users_on_unlock_token', unique: true
  end

  create_table 'users_roles', id: false, force: :cascade do |t|
    t.bigint 'user_id'
    t.bigint 'role_id'
    t.index ['role_id'], name: 'index_users_roles_on_role_id'
    t.index %w[user_id role_id], name: 'index_users_roles_on_user_id_and_role_id'
    t.index ['user_id'], name: 'index_users_roles_on_user_id'
  end

  create_table 'videos', force: :cascade do |t|
    t.string 'title'
    t.date 'is_locked'
    t.bigint 'lesson_id', null: false
    t.bigint 'upload_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['lesson_id'], name: 'index_videos_on_lesson_id'
    t.index ['upload_id'], name: 'index_videos_on_upload_id'
  end

  add_foreign_key 'chapters', 'courses'
  add_foreign_key 'course_categories', 'categories'
  add_foreign_key 'course_categories', 'courses'
  add_foreign_key 'courses', 'users'
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
  add_foreign_key 'videos', 'lessons'
  add_foreign_key 'videos', 'uploads'
end
