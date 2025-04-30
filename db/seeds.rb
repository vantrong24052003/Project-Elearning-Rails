# frozen_string_literal: true

Progress.destroy_all
VideoProgress.destroy_all
Video.destroy_all
Upload.destroy_all
QuizQuestion.destroy_all
QuizAttempt.destroy_all
Question.destroy_all
Quiz.destroy_all
Lesson.destroy_all
Chapter.destroy_all
Enrollment.destroy_all
CourseCategory.destroy_all
Course.destroy_all
Category.destroy_all
Role.destroy_all
User.destroy_all

%w[
  progresses video_progresses videos uploads quiz_questions quiz_attempts
  questions quizzes lessons chapters enrollments course_categories
  courses categories users_roles roles users
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
category3 = Category.create!(name: 'Business', description: 'Business and management skills.')
category4 = Category.create!(name: 'Data Analysis', description: 'Data analysis and visualization.')
puts '✅ Created categories.'

demo_videos = [
  ActionController::Base.helpers.asset_path('video1.mp4'),
  ActionController::Base.helpers.asset_path('video2.mp4'),
  ActionController::Base.helpers.asset_path('video3.mp4'),
  ActionController::Base.helpers.asset_path('video4.mp4')
]

course_thumbnails = [
  'https://i.ytimg.com/vi/jWj0sodsWog/maxresdefault.jpg',
  'https://trungtamtinhocdanang.com/wp-content/uploads/2021/11/khoa-hoc-excel-cap-toc-tu-co-ban-den-nang-cao.jpg',
  'https://tse3.mm.bing.net/th?id=OIP.YckuMgINHv97aN7G4AEogwHaFj&pid=Api&P=0&h=180',
  'https://codestar.vn/wp-content/uploads/2023/03/MicrosoftTeams-image-39.png'
]

course_titles = [
  'Data Analysis Mastery',
  'Advanced Excel Skills',
  'Business Law Fundamentals',
  'Agile Project Management',
  'Python Programming',
  'Web Development',
  'Digital Marketing',
  'Machine Learning',
  'UI/UX Design',
  'Project Management'
]

course_descriptions = [
  'Master data analysis techniques and tools.',
  'Learn advanced Excel techniques for business.',
  'Learn essential business law concepts.',
  'Master Agile methodologies and practices.',
  'Learn Python programming from scratch.',
  'Build modern web applications.',
  'Learn digital marketing strategies.',
  'Understand machine learning concepts.',
  'Create beautiful user interfaces.',
  'Master project management skills.'
]

uploads = demo_videos.map.with_index do |video_path, index|
  Upload.create!(
    file_type: 'video',
    cdn_url: video_path,
    thumbnail_path: course_thumbnails[index % course_thumbnails.length],
    duration: rand(200..500),
    resolution: '1080p',
    user_id: instructor.id,
    status: 'active'
  )
end

categories = [category1, category2, category3, category4]
languages = %w[English Vietnamese Japanese]
prices = [29.99, 49.99, 99.99, 149.99, 199.99]

100.times do |i|
  title_index = rand(0..course_titles.length - 1)
  course = Course.create!(
    title: "#{course_titles[title_index]} #{i + 1}",
    description: course_descriptions[title_index],
    price: prices.sample,
    language: languages.sample,
    status: 'published',
    user_id: instructor.id,
    category_id: categories.sample.id,
    thumbnail_path: course_thumbnails.sample,
    demo_video_path: demo_videos.sample,
    is_free: rand < 0.1
  )

  CourseCategory.create!(
    course: course,
    category: Category.find(course.category_id)
  )

  (2..4).to_a.sample.times do |j|
    chapter = Chapter.create!(
      title: "Chapter #{j + 1}: #{course_titles[title_index]}",
      position: j + 1,
      course: course
    )

    (3..5).to_a.sample.times do |k|
      lesson = Lesson.create!(
        title: "Lesson #{k + 1}: #{course_descriptions[title_index]}",
        description: "Detailed lesson about #{course_titles[title_index]}",
        position: k + 1,
        chapter: chapter
      )

      (2..3).to_a.sample.times do |l|
        upload = uploads.sample
        Video.create!(
          title: "Video #{l + 1}: #{lesson.title}",
          lesson: lesson,
          upload: upload,
          thumbnail: upload.thumbnail_path,
          position: l + 1,
          is_locked: l.zero? ? nil : '1985-05-10'
        )
      end
    end
  end

  next unless rand < 0.3

  Enrollment.create!(
    user: student,
    course: course,
    status: %i[active pending].sample,
    payment_code: SecureRandom.hex(4).upcase,
    payment_method: ['payment', nil].sample,
    amount: course.price,
    paid_at: Time.current - rand(1..30).days,
    enrolled_at: Time.current - rand(1..30).days,
    completed_at: rand < 0.5 ? Time.current : nil,
    note: ['Completed payment successfully', 'Payment pending', nil].sample
  )
end

puts '✅ Created 100 courses with chapters, lessons, videos and enrollments.'

courses = Course.all.sample(10)
courses.each do |course|
  question = Question.create!(
    content: "Sample question for #{course.title}?",
    options: { 'A' => 'Option A', 'B' => 'Option B', 'C' => 'Option C' },
    correct_option: rand(1..3),
    explanation: "Explanation for #{course.title}",
    difficulty: %w[easy medium hard].sample,
    course: course,
    user: [admin, instructor].sample
  )

  quiz = Quiz.create!(
    title: "Quiz for #{course.title}",
    is_exam: [true, false].sample,
    time_limit: [20, 30, 40, 50, 60].sample,
    course: course
  )

  QuizQuestion.create!(quiz: quiz, question: question)
end

puts '✅ Created questions and quizzes.'

Course.all.sample(20).each do |course|
  random_lesson = course.chapters.sample&.lessons&.sample
  next unless random_lesson

  Progress.create!(
    user: student,
    course: course,
    lesson: random_lesson,
    status: %i[pending inprogress done].sample # Sửa lại giá trị status hợp lệ
  )
end

puts '✅ Created progress records.'

puts "\n🎉 Seed data completed successfully!"
