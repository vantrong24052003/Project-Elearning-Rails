# frozen_string_literal: true

Progress.destroy_all
Video.destroy_all
Upload.destroy_all
QuizQuestion.destroy_all
Question.destroy_all
Quiz.destroy_all
Lesson.destroy_all
Chapter.destroy_all
CourseCategory.destroy_all
Category.destroy_all
Course.destroy_all
Role.destroy_all
User.destroy_all

%w[
  videos uploads progresses quiz_questions questions quizzes
  lessons chapters course_categories categories courses roles users
].each do |table_name|
  ActiveRecord::Base.connection.reset_pk_sequence!(table_name)
end

admin = begin
  user = User.new(
    email: 'admin@gmail.com', password: 'Admin123@',
    name: 'Admin User', phone: '1234567890', address: 'Admin Address',
    bio: 'This is an admin user', date_of_birth: '1985-05-10'
  )
  user.skip_confirmation!
  user.confirm
  user.save
  user
end

instructor = begin
  user = User.new(
    email: 'instructor@gmail.com', password: 'Admin123@',
    name: 'Instructor User', phone: '0987654321', address: 'Instructor Address',
    bio: 'This is an instructor user', date_of_birth: '1990-07-15'
  )
  user.skip_confirmation!
  user.confirm
  user.save
  user
end

student = begin
  user = User.new(
    email: 'student@gmail.com', password: 'Admin123@',
    name: 'Student User', phone: '1122334455', address: 'Student Address',
    bio: 'This is a student user', date_of_birth: '2000-02-20'
  )
  user.skip_confirmation!
  user.confirm
  user.save
  user
end
puts '✅ Created users.'

admin_role = Role.create!(name: 'admin')
instructor_role = Role.create!(name: 'instructor')
student_role = Role.create!(name: 'student')

admin.roles << admin_role
instructor.roles << instructor_role
student.roles << student_role
puts '✅ Assigned roles.'

category1 = Category.create!(name: 'Programming', description: 'All about programming languages.')
category2 = Category.create!(name: 'Design', description: 'Design and creative skills.')
puts '✅ Created categories.'

course1 = Course.create!(
  title: 'Ruby on Rails for Beginners',
  description: 'Learn Ruby on Rails from scratch.',
  price: 50.0, language: 'English', status: 'published', user_id: admin.id,
  thumbnail_path: 'https://upload.wikimedia.org/wikipedia/commons/1/14/No_Image_Available.jpg'
)

course2 = Course.create!(
  title: 'Design Principles',
  description: 'Understand design principles for web and mobile.',
  price: 30.0, language: 'English', status: 'published', user_id: instructor.id,
  thumbnail_path: 'https://upload.wikimedia.org/wikipedia/commons/1/14/No_Image_Available.jpg'
)

CourseCategory.create!(course: course1, category: category1)
CourseCategory.create!(course: course2, category: category2)
puts '✅ Created courses and assigned categories.'

chapter1 = Chapter.create!(title: 'Introduction to Ruby', position: 1, course: course1)
chapter2 = Chapter.create!(title: 'Basic Design Concepts', position: 1, course: course2)

lesson1 = Lesson.create!(title: 'Getting Started with Ruby', description: 'Intro to Ruby', position: 1,
                         chapter: chapter1)
lesson2 = Lesson.create!(title: 'Understanding UI', description: 'UI Basics', position: 1, chapter: chapter2)
puts '✅ Created chapters and lessons.'

video_path = Rails.root.join('app/assets/videos/video.mp4')

upload1 = Upload.create!(
  file_type: 'video',
  cdn_url: video_path.to_s,
  thumbnail_path: 'https://upload.wikimedia.org/wikipedia/commons/1/14/No_Image_Available.jpg',
  duration: 300,
  resolution: '1080p',
  user_id: admin.id,
  status: 'active'
)

upload2 = Upload.create!(
  file_type: 'video',
  cdn_url: video_path.to_s,
  thumbnail_path: 'https://upload.wikimedia.org/wikipedia/commons/1/14/No_Image_Available.jpg',
  duration: 250,
  resolution: '720p',
  user_id: instructor.id,
  status: 'active'
)
puts '✅ Created uploads from local video files.'

Video.create!(title: 'Ruby Basics', lesson: lesson1, upload: upload1, is_locked: '1985-05-10')
Video.create!(title: 'UI Design Basics', lesson: lesson2, upload: upload2)
puts '✅ Created videos.'

question1 = Question.create!(
  content: 'What is Ruby?',
  options: { 'A' => 'A language', 'B' => 'A framework' },
  correct_option: 1,
  explanation: 'Ruby is a programming language.',
  difficulty: 'easy',
  course: course1,
  user: admin
)

question2 = Question.create!(
  content: 'What is UX?',
  options: { 'A' => 'User Experience', 'B' => 'User Experience Design' },
  correct_option: 1,
  explanation: 'UX stands for User Experience.',
  difficulty: 'easy',
  course: course2,
  user: instructor
)
puts '✅ Created questions.'

quiz1 = Quiz.create!(title: 'Ruby Basics Quiz', is_exam: false, time_limit: 20, course: course1)
quiz2 = Quiz.create!(title: 'UI Design Principles', is_exam: true, time_limit: 30, course: course2)

QuizQuestion.create!(quiz: quiz1, question: question1)
QuizQuestion.create!(quiz: quiz2, question: question2)

puts '✅ Created quizzes and linked questions.'

Progress.create!(user: student, course: course1, lesson: lesson1, status: 'in_progress')
puts '✅ Created progress.'

puts "\n🎉 Seed data completed successfully!"
