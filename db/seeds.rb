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
Enrollment.destroy_all
Course.destroy_all
Role.destroy_all
User.destroy_all

%w[
  videos uploads progresses quiz_questions questions quizzes
  lessons chapters course_categories categories enrollments courses roles users
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

demo_videos = [
  ActionController::Base.helpers.asset_path('video1.mp4'),
  ActionController::Base.helpers.asset_path('video2.mp4'),
  ActionController::Base.helpers.asset_path('video3.mp4'),
  ActionController::Base.helpers.asset_path('video4.mp4')
]

thumbnails = [
  'https://example.com/thumbnails/ruby1.jpg',
  'https://example.com/thumbnails/ruby2.jpg',
  'https://example.com/thumbnails/ruby3.jpg',
  'https://example.com/thumbnails/ruby4.jpg'
]

uploads = demo_videos.map.with_index do |video_path, index|
  Upload.create!(
    file_type: 'video',
    cdn_url: video_path,
    thumbnail_path: thumbnails[index],
    duration: rand(200..500),
    resolution: '1080p',
    user_id: instructor.id,
    status: 'active'
  )
end

course1 = Course.create!(
  title: 'Ruby on Rails for Beginners',
  description: 'Learn Ruby on Rails from scratch.',
  price: 50.0, language: 'English', status: 'published', user_id: admin.id,
  thumbnail_path: 'https://upload.wikimedia.org/wikipedia/commons/1/14/No_Image_Available.jpg',
  demo_video_path: demo_videos[0]
)

course2 = Course.create!(
  title: 'Design Principles',
  description: 'Understand design principles for web and mobile.',
  price: 30.0, language: 'English', status: 'published', user_id: instructor.id,
  thumbnail_path: 'https://upload.wikimedia.org/wikipedia/commons/1/14/No_Image_Available.jpg',
  demo_video_path: demo_videos[1]
)

course3 = Course.create!(
  title: 'Advanced Web Development',
  description: 'Master modern web development techniques.',
  price: 75.0, language: 'English', status: 'published', user_id: instructor.id,
  thumbnail_path: 'https://upload.wikimedia.org/wikipedia/commons/1/14/No_Image_Available.jpg',
  demo_video_path: demo_videos[2]
)

course4 = Course.create!(
  title: 'UI/UX Design Masterclass',
  description: 'Create beautiful and functional user interfaces.',
  price: 60.0, language: 'English', status: 'published', user_id: instructor.id,
  thumbnail_path: 'https://upload.wikimedia.org/wikipedia/commons/1/14/No_Image_Available.jpg',
  demo_video_path: demo_videos[3]
)

CourseCategory.create!(course: course1, category: category1)
CourseCategory.create!(course: course2, category: category2)
CourseCategory.create!(course: course3, category: category1)
CourseCategory.create!(course: course4, category: category2)
puts '✅ Created courses and assigned categories.'

Enrollment.create!(
  user: student,
  course: course1,
  status: :active,
  enrolled_at: Time.current,
  price_paid: 50.0
)

Enrollment.create!(
  user: student,
  course: course2,
  status: :pending,
  enrolled_at: Time.current,
  price_paid: 30.0
)

Enrollment.create!(
  user: instructor,
  course: course1,
  status: :active,
  enrolled_at: 1.month.ago,
  price_paid: 50.0
)
puts '✅ Created enrollments.'

chapter1 = Chapter.create!(title: 'Introduction to Ruby', position: 1, course: course1)
chapter2 = Chapter.create!(title: 'Basic Design Concepts', position: 1, course: course2)

lesson1 = Lesson.create!(title: 'Getting Started with Ruby', description: 'Intro to Ruby', position: 1,
                         chapter: chapter1)
lesson2 = Lesson.create!(title: 'Understanding UI', description: 'UI Basics', position: 1, chapter: chapter2)
puts '✅ Created chapters and lessons.'

[lesson1, lesson2].each do |lesson|
  rand(2..4).times do |i|
    upload = uploads.sample
    Video.create!(
      title: "#{lesson.title} - Part #{i + 1}",
      lesson: lesson,
      upload: upload,
      thumbnail: upload.thumbnail_path,
      is_locked: i.zero? ? nil : '1985-05-10' # Chỉ video đầu tiên không khóa
    )
  end
end

puts '✅ Created multiple videos for each lesson.'

chapter3 = Chapter.create!(
  title: 'Advanced Ruby',
  position: 3,
  course: course1
)

chapter4 = Chapter.create!(
  title: 'Ruby Best Practices',
  position: 4,
  course: course1
)

lesson3 = Lesson.create!(title: 'Ruby OOP Concepts', description: 'Learn about Object-Oriented Programming in Ruby', chapter: chapter1, position: 3)
lesson4 = Lesson.create!(title: 'Ruby Modules & Mixins', description: 'Understanding modules and mixins in Ruby', chapter: chapter1, position: 4)

lesson5 = Lesson.create!(title: 'Metaprogramming in Ruby', description: 'Advanced metaprogramming concepts', chapter: chapter3, position: 1)
lesson6 = Lesson.create!(title: 'Ruby DSL Design', description: 'Creating Domain Specific Languages', chapter: chapter3, position: 2)

lesson7 = Lesson.create!(title: 'Code Organization', description: 'Best practices for organizing Ruby code', chapter: chapter4, position: 1)
lesson8 = Lesson.create!(title: 'Testing Strategies', description: 'Different approaches to testing Ruby code', chapter: chapter4, position: 2)

[lesson3, lesson4, lesson5, lesson6, lesson7, lesson8].each do |lesson|
  rand(2..4).times do |i|
    upload = uploads.sample
    Video.create!(
      title: "#{lesson.title} - Part #{i + 1}",
      lesson: lesson,
      upload: upload,
      thumbnail: upload.thumbnail_path,
      is_locked: i.zero? ? nil : '1985-05-10' # Chỉ video đầu tiên không khóa
    )
  end
end

puts '✅ Created multiple videos for each lesson.'

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

# Tạo progress cho student
Progress.create!(user: student, course: course1, lesson: lesson1, status: :inprogress)
puts '✅ Created progress.'

puts "\n🎉 Seed data completed successfully!"
