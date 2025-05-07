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

uploads = [
  Upload.create!(
    id: '3499d245-c563-44ab-8d2e-1420ffc79813',
    file_type: 'mp4',
    cdn_url: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/3499d245-c563-44ab-8d2e-1420ffc79813/hls/master.m3u8',
    thumbnail_path: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/3499d245-c563-44ab-8d2e-1420ffc79813/thumbnail.jpg',
    duration: 34,
    status: 'success',
    user_id: instructor.id,
    created_at: '2025-05-07 04:35:49.450872',
    updated_at: '2025-05-07 04:36:26.943297',
    formats: %w[mp4 hls],
    progress: 100,
    processing_log: 'Vẽ tranh tặng Crush siêu đơn giản- Lê Công Duy Tính #shorts.mp4',
    quality_360p_url: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/3499d245-c563-44ab-8d2e-1420ffc79813/hls/360p/playlist.m3u8',
    quality_480p_url: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/3499d245-c563-44ab-8d2e-1420ffc79813/hls/480p/playlist.m3u8',
    quality_720p_url: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/3499d245-c563-44ab-8d2e-1420ffc79813/hls/720p/playlist.m3u8'
  ),
  Upload.create!(
    id: '7c43af26-b9e8-4295-a2c1-d311247a9980',
    file_type: 'mp4',
    cdn_url: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/7c43af26-b9e8-4295-a2c1-d311247a9980/hls/master.m3u8',
    thumbnail_path: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/7c43af26-b9e8-4295-a2c1-d311247a9980/thumbnail.jpg',
    duration: 30,
    status: 'success',
    user_id: instructor.id,
    created_at: '2025-05-07 04:35:49.445987',
    updated_at: '2025-05-07 04:36:29.976609',
    formats: %w[mp4 hls],
    progress: 100,
    processing_log: 'Một biệt đội phản anh hùng _bất thường_.mp4',
    quality_360p_url: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/7c43af26-b9e8-4295-a2c1-d311247a9980/hls/360p/playlist.m3u8',
    quality_480p_url: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/7c43af26-b9e8-4295-a2c1-d311247a9980/hls/480p/playlist.m3u8',
    quality_720p_url: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/7c43af26-b9e8-4295-a2c1-d311247a9980/hls/720p/playlist.m3u8'
  ),
  Upload.create!(
    id: '9d3df3e6-32cc-4c85-a1d5-2a419c301030',
    file_type: 'mp4',
    cdn_url: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/9d3df3e6-32cc-4c85-a1d5-2a419c301030/hls/master.m3u8',
    thumbnail_path: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/9d3df3e6-32cc-4c85-a1d5-2a419c301030/thumbnail.jpg',
    duration: 24,
    status: 'success',
    user_id: instructor.id,
    created_at: '2025-05-07 04:35:49.664633',
    updated_at: '2025-05-07 04:36:30.74805',
    formats: %w[mp4 hls],
    progress: 100,
    processing_log: 'Mất chất luôn 🙃 #takhongngu.mp4',
    quality_360p_url: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/9d3df3e6-32cc-4c85-a1d5-2a419c301030/hls/360p/playlist.m3u8',
    quality_480p_url: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/9d3df3e6-32cc-4c85-a1d5-2a419c301030/hls/480p/playlist.m3u8',
    quality_720p_url: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/9d3df3e6-32cc-4c85-a1d5-2a419c301030/hls/720p/playlist.m3u8'
  ),
  Upload.create!(
    id: 'e2756ae3-95df-4a16-8323-f6278feae728',
    file_type: 'mp4',
    cdn_url: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/e2756ae3-95df-4a16-8323-f6278feae728/hls/master.m3u8',
    thumbnail_path: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/e2756ae3-95df-4a16-8323-f6278feae728/thumbnail.jpg',
    duration: 12,
    status: 'success',
    user_id: instructor.id,
    created_at: '2025-05-07 04:35:49.323788',
    updated_at: '2025-05-07 04:36:12.065124',
    formats: %w[mp4 hls],
    progress: 100,
    processing_log: 'đém ngược 10 giây.mp4',
    quality_360p_url: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/e2756ae3-95df-4a16-8323-f6278feae728/hls/360p/playlist.m3u8',
    quality_480p_url: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/e2756ae3-95df-4a16-8323-f6278feae728/hls/480p/playlist.m3u8',
    quality_720p_url: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/e2756ae3-95df-4a16-8323-f6278feae728/hls/720p/playlist.m3u8'
  )
]

demo_videos = uploads.map(&:cdn_url)

course_thumbnails = uploads.map(&:thumbnail_path)

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
        success_uploads = uploads.select { |upload| upload.status == 'success' }
        available_upload = success_uploads.any? ? success_uploads.sample : uploads.sample

        Video.create!(
          title: "Video #{l + 1}: #{lesson.title}",
          lesson: lesson,
          upload: available_upload,
          thumbnail: available_upload.thumbnail_path,
          position: l + 1,
          is_locked: l.zero? ? nil : '1985-05-10',
          moderation_status: %i[pending approved rejected locked].sample
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

QUIZ_TOPICS = {
  'Programming' => [
    'Cơ bản về ngôn ngữ lập trình', 'Cấu trúc dữ liệu và thuật toán',
    'Lập trình hướng đối tượng', 'Framework và thư viện', 'Phát triển ứng dụng web'
  ],
  'Design' => [
    'Nguyên tắc thiết kế cơ bản', 'Màu sắc và bố cục',
    'UX/UI Design', 'Thiết kế đáp ứng', 'Công cụ thiết kế chuyên nghiệp'
  ],
  'Business' => [
    'Quản lý dự án', 'Marketing và bán hàng',
    'Tài chính cơ bản', 'Chiến lược kinh doanh', 'Quản lý nhân sự'
  ],
  'Data Analysis' => [
    'Phân tích dữ liệu cơ bản', 'Thống kê ứng dụng',
    'Trực quan hóa dữ liệu', 'Machine Learning cơ bản', 'Công cụ phân tích dữ liệu'
  ]
}.freeze

QUESTION_TEMPLATES = {
  'Programming' => [
    'Phương pháp nào được sử dụng để tối ưu hóa TOPIC?',
    'Nguyên tắc quan trọng nhất trong TOPIC là gì?',
    'Công cụ nào phổ biến nhất để phát triển TOPIC?',
    'Cách giải quyết vấn đề TOPIC hiệu quả nhất?'
  ],
  'Design' => [
    'Nguyên tắc thiết kế nào quan trọng nhất trong TOPIC?',
    'Xu hướng mới nhất trong lĩnh vực TOPIC?',
    'Công cụ nào tốt nhất cho TOPIC?',
    'Cách áp dụng TOPIC vào dự án thực tế?'
  ],
  'Business' => [
    'Chiến lược TOPIC nào hiệu quả nhất cho startup?',
    'Yếu tố quyết định thành công trong TOPIC?',
    'Phương pháp đo lường hiệu quả của TOPIC?',
    'Xu hướng mới trong TOPIC năm nay?'
  ],
  'Data Analysis' => [
    'Kỹ thuật nào tốt nhất cho TOPIC?',
    'Công cụ phân tích nào phù hợp nhất với TOPIC?',
    'Cách xử lý missing data trong TOPIC?',
    'Mô hình nào cho độ chính xác cao nhất trong TOPIC?'
  ]
}.freeze

ANSWER_OPTIONS = {
  'Programming' => [
    'Sử dụng thuật toán tối ưu hóa và cấu trúc dữ liệu phù hợp',
    'Áp dụng mẫu thiết kế và kiến trúc phân lớp',
    'Sử dụng các thư viện và framework hiện đại',
    'Áp dụng các kỹ thuật lập trình song song'
  ],
  'Design' => [
    'Sử dụng nguyên tắc thiết kế tối giản và tương phản',
    'Áp dụng lý thuyết màu sắc và bố cục cân đối',
    'Tối ưu hóa trải nghiệm người dùng và khả năng tiếp cận',
    'Thiết kế dựa trên nghiên cứu người dùng và phản hồi'
  ],
  'Business' => [
    'Phân tích thị trường và đối thủ cạnh tranh',
    'Xây dựng kế hoạch kinh doanh và chiến lược marketing',
    'Tối ưu hóa quy trình và nguồn lực',
    'Áp dụng các mô hình kinh doanh đổi mới'
  ],
  'Data Analysis' => [
    'Áp dụng phương pháp thống kê và mô hình dự đoán',
    'Sử dụng công cụ phân tích dữ liệu và trực quan hóa',
    'Xử lý dữ liệu lớn và phân tích theo thời gian thực',
    'Kết hợp nhiều nguồn dữ liệu và kỹ thuật phân tích'
  ]
}.freeze

EXAM_QUESTIONS = {
  'Programming' => [
    {
      content_prefix: 'Với ngôn ngữ lập trình ',
      content_subjects: ['Python', 'JavaScript', 'Java', 'C++', 'Ruby'],
      content_suffix: ', đâu là cách tốt nhất để ',
      content_tasks: ['xử lý bất đồng bộ', 'tối ưu hóa hiệu suất', 'triển khai mô hình MVC', 'quản lý bộ nhớ'],
      options: [
        'Sử dụng Promise và async/await để quản lý luồng xử lý',
        'Áp dụng đa luồng và xử lý song song khi thích hợp',
        'Tận dụng các thư viện chuyên dụng và framework tối ưu',
        'Sử dụng mẫu thiết kế Singleton để quản lý tài nguyên'
      ]
    }
  ],
  'Design' => [
    {
      content_prefix: 'Trong lĩnh vực ',
      content_subjects: ['UI/UX Design', 'Web Design', 'Mobile Design', 'Graphic Design'],
      content_suffix: ', làm thế nào để ',
      content_tasks: ['tạo trải nghiệm người dùng tốt nhất', 'thiết kế giao diện hiệu quả',
                      'áp dụng nguyên tắc accessibility', 'cân bằng thẩm mỹ và chức năng'],
      options: [
        'Áp dụng nguyên tắc thiết kế tối giản và nhất quán',
        'Sử dụng prototyping và testing với người dùng thật',
        'Tuân thủ các hướng dẫn thiết kế của nền tảng',
        'Tập trung vào trải nghiệm người dùng và khả năng sử dụng'
      ]
    }
  ],
  'Business' => [
    {
      content_prefix: 'Trong phát triển chiến lược ',
      content_subjects: ['marketing', 'kinh doanh', 'quản lý nhân sự', 'tài chính'],
      content_suffix: ', yếu tố nào quan trọng nhất để ',
      content_tasks: ['tăng doanh thu', 'giảm chi phí', 'tối ưu hóa quy trình', 'nâng cao hiệu suất'],
      options: [
        'Phân tích dữ liệu và KPI để đưa ra quyết định dựa trên số liệu',
        'Xây dựng đội ngũ chuyên nghiệp và văn hóa công ty mạnh mẽ',
        'Áp dụng các chiến lược đổi mới và phương pháp tiếp cận mới',
        'Tối ưu hóa quy trình và tự động hóa các nhiệm vụ lặp lại'
      ]
    }
  ],
  'Data Analysis' => [
    {
      content_prefix: 'Trong phân tích dữ liệu ',
      content_subjects: ['lớn', 'thời gian thực', 'dự đoán', 'hành vi người dùng'],
      content_suffix: ', phương pháp nào hiệu quả nhất để ',
      content_tasks: ['xử lý dữ liệu thiếu', 'trực quan hóa kết quả', 'dự đoán xu hướng', 'phát hiện bất thường'],
      options: [
        'Sử dụng thuật toán học máy và phân tích dự đoán',
        'Áp dụng thống kê nâng cao và phân tích hồi quy',
        'Kết hợp nhiều nguồn dữ liệu và phương pháp phân tích',
        'Sử dụng công cụ trực quan hóa và dashboard tương tác'
      ]
    }
  ]
}.freeze

puts 'Tạo bài kiểm tra cho các khóa học...'

def create_quiz_for_course(course, is_exam = false)
  category = course.categories.first
  category_name = category ? category.name : 'Programming'

  if is_exam
    create_exam_for_course(course, category_name)
  else
    create_practice_quiz_for_course(course, category_name)
  end
end

def create_practice_quiz_for_course(course, category_name)
  topics = QUIZ_TOPICS[category_name]
  question_templates = QUESTION_TEMPLATES[category_name]
  answers = ANSWER_OPTIONS[category_name]
  topic = topics.sample
  title = "#{topic} - #{course.title.split.first(2).join(' ')}"

  quiz = Quiz.create!(
    title: title,
    is_exam: false,
    time_limit: [10, 15, 20, 25, 30].sample,
    course: course
  )

  rand(3..7).times do |j|
    template = question_templates.sample
    content = template.gsub('TOPIC', topic.downcase) + " (##{j + 1})"

    question = Question.create!(
      content: content,
      options: answers.shuffle,
      correct_option: rand(0..3),
      explanation: "Giải thích chi tiết: #{answers.sample} là phương pháp hiệu quả nhất cho #{topic.downcase}.",
      difficulty: %w[easy medium hard].sample,
      course: course,
      user: course.user
    )

    QuizQuestion.create!(quiz: quiz, question: question)
  end

  create_quiz_attempts(quiz, course)

  quiz
end

def create_exam_for_course(course, category_name)
  exam = Quiz.create!(
    title: "Bài thi cuối khóa - #{course.title.truncate(30)}",
    is_exam: true,
    time_limit: [30, 45, 60].sample,
    course: course
  )

  exam_templates = EXAM_QUESTIONS[category_name] || EXAM_QUESTIONS['Programming']

  rand(10..15).times do |_j|
    template = exam_templates.sample

    subject = template[:content_subjects].sample
    task = template[:content_tasks].sample
    content = "#{template[:content_prefix]}#{subject}#{template[:content_suffix]}#{task}?"

    question = Question.create!(
      content: content,
      options: template[:options].shuffle,
      correct_option: rand(0..3),
      explanation: "Lý giải chi tiết: #{template[:options].sample} là phương pháp tối ưu cho nhiều trường hợp.",
      difficulty: %w[medium hard].sample,
      course: course,
      user: course.user
    )

    QuizQuestion.create!(quiz: exam, question: question)
  end

  exam
end

def create_quiz_attempts(quiz, course)
  return unless course.enrolled_users.any? && rand < 0.7

  students = course.enrolled_users.sample(rand(1..3))

  students.each do |student|
    answers = {}
    correct_count = 0

    quiz.questions.each do |q|
      user_answer = rand(0..3)
      answers[q.id.to_s] = user_answer
      correct_count += 1 if user_answer == q.correct_option
    end

    score = quiz.questions.any? ? (correct_count.to_f / quiz.questions.count * 100).round : 0

    time_spent = rand((quiz.time_limit * 30)..(quiz.time_limit * 60))

    QuizAttempt.create!(
      quiz: quiz,
      user: student,
      score: score,
      time_spent: time_spent,
      answers: answers
    )
  end
end

10.times do
  course = Course.all.sample
  create_quiz_for_course(course, false)
end

10.times do
  course = Course.all.sample
  create_quiz_for_course(course, true)
end

puts "✅ Đã tạo #{Quiz.count} bài kiểm tra với #{Question.count} câu hỏi và #{QuizAttempt.count} lần làm bài."

Course.all.sample(20).each do |course|
  random_lesson = course.chapters.sample&.lessons&.sample
  next unless random_lesson

  Progress.create!(
    user: student,
    course: course,
    lesson: random_lesson,
    status: %i[pending inprogress done].sample
  )
end

puts '✅ Created progress records.'

puts "Seeding course ratings..."
Course.find_each do |course|
  random_rating = rand(3.0..5.0).round(2)
  course.update!(rating: random_rating)
end

puts "✅ Created course ratings!"

puts "\n🎉 Seed data completed successfully!"
