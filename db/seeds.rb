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

puts 'Creating admin student and instructor...'

admin = begin
  user = User.new(
    email: 'trongdn2405@gmail.com', password: 'Admin123@',
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
    email: 'trongtk24052003@gmail.com', password: 'Admin123@',
    name: 'Instructor User', phone: '0987654321', address: 'Instructor Address',
    bio: 'This is an instructor user', date_of_birth: '1990-07-15'
  )
  user.skip_confirmation!
  user.confirm
  user.save
  user
end

admin_role = Role.create!(name: 'admin')
instructor_role = Role.create!(name: 'instructor')
student_role = Role.create!(name: 'student')

admin.roles << admin_role
instructor.roles << instructor_role

5.times do |i|
  user = User.new(
    email: "instructor#{i}@gmail.com",
    password: 'Admin123@',
    name: "Instructor #{rand(1..100)}",
    phone: "098#{rand(1_000_000..9_999_999)}",
    address: "Address #{rand(1..100)}",
    bio: "Professional instructor with #{rand(2..10)} years of experience",
    date_of_birth: (Date.today - rand(25..45).years).strftime('%Y-%m-%d')
  )
  user.skip_confirmation!
  user.confirm
  user.save
  user.roles << instructor_role
end

10.times do |i|
  user = User.new(
    email: "student#{i}@gmail.com",
    password: 'Admin123@',
    name: "Student #{rand(1..100)}",
    phone: "09#{rand(10_000_000..99_999_999)}",
    address: "Address #{rand(1..100)}",
    bio: 'Enthusiastic learner interested in various subjects',
    date_of_birth: (Date.today - rand(18..30).years).strftime('%Y-%m-%d')
  )
  user.skip_confirmation!
  user.confirm
  user.save
  user.roles << student_role
end

puts '✅ Created users.'
puts '✅ Assigned roles.'

category1 = Category.create!(name: 'Programming', description: 'All about programming languages.')
category2 = Category.create!(name: 'Design', description: 'Design and creative skills.')
category3 = Category.create!(name: 'Business', description: 'Business and management skills.')
category4 = Category.create!(name: 'Data Analysis', description: 'Data analysis and visualization.')
puts '✅ Created categories.'

def fetch_transcription_text(json_url)
  uri = URI.parse(json_url)
  bucket = uri.host.split('.').first
  key = uri.path.sub(/^\//, '')

  s3_conf = YAML.safe_load(ERB.new(File.read(Rails.root.join('config/storage.yml'))).result)['amazon']

  s3 = Aws::S3::Client.new(
    region: s3_conf['region'],
    access_key_id: Rails.application.credentials.dig(:aws, :access_key_id),
    secret_access_key: Rails.application.credentials.dig(:aws, :secret_access_key)
  )

  s3.head_object(bucket: bucket, key: key)
  body = s3.get_object(bucket: bucket, key: key).body.read
  data = JSON.parse(body)
  data.dig('results', 'transcripts', 0, 'transcript') || 'Không có nội dung transcript'

rescue => e
  "Không thể đọc transcript: #{e.message}"
end

puts 'Creating uploads...'

uploads = [         
  Upload.create!(
    id: '0a9126af-f394-42c5-acff-e7bd0e1da25c',
    file_type: 'mp4',
    cdn_url: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/0a9126af-f394-42c5-acff-e7bd0e1da25c/hls/master.m3u8',
    thumbnail_path: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/0a9126af-f394-42c5-acff-e7bd0e1da25c/thumbnail.jpg',
    duration: 34,
    status: 'success',
    user_id: instructor.id,
    created_at: Faker::Time.between(from: 6.months.ago, to: Time.current),
    updated_at: Faker::Time.between(from: 6.months.ago, to: Time.current),
    formats: %w[mp4 hls],
    progress: 100,
    transcription: fetch_transcription_text('https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/0a9126af-f394-42c5-acff-e7bd0e1da25c/transcription/transcript.json'),
    transcription_status: 'completed',
    processing_log: 'Vẽ tranh tặng Crush siêu đơn giản- Lê Công Duy Tính #shorts.mp4',
    quality_360p_url: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/0a9126af-f394-42c5-acff-e7bd0e1da25c/hls/360p/playlist.m3u8',
    quality_480p_url: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/0a9126af-f394-42c5-acff-e7bd0e1da25c/hls/480p/playlist.m3u8',
    quality_720p_url: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/0a9126af-f394-42c5-acff-e7bd0e1da25c/hls/720p/playlist.m3u8'
  ),
  Upload.create!(
    id: '7c9faf8f-c371-4499-91d6-5968c384a4be',
    file_type: 'mp4',
    cdn_url: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/7c9faf8f-c371-4499-91d6-5968c384a4be/hls/master.m3u8',
    thumbnail_path: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/7c9faf8f-c371-4499-91d6-5968c384a4be/thumbnail.jpg',
    duration: 30,
    status: 'success',
    user_id: instructor.id,
    created_at: Faker::Time.between(from: 6.months.ago, to: Time.current),
    updated_at: Faker::Time.between(from: 6.months.ago, to: Time.current),
    formats: %w[mp4 hls],
    progress: 100,
    transcription: fetch_transcription_text('https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/7c9faf8f-c371-4499-91d6-5968c384a4be/transcription/transcript.json'),
    transcription_status: 'completed',
    processing_log: 'Một biệt đội phản anh hùng _bất thường_.mp4',
    quality_360p_url: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/7c9faf8f-c371-4499-91d6-5968c384a4be/hls/360p/playlist.m3u8',
    quality_480p_url: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/7c9faf8f-c371-4499-91d6-5968c384a4be/hls/480p/playlist.m3u8',
    quality_720p_url: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/7c9faf8f-c371-4499-91d6-5968c384a4be/hls/720p/playlist.m3u8'
  ),
  Upload.create!(
    id: 'cc2fa2bb-7726-4f2c-9bff-a39773454702',
    file_type: 'mp4',
    cdn_url: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/cc2fa2bb-7726-4f2c-9bff-a39773454702/hls/master.m3u8',
    thumbnail_path: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/cc2fa2bb-7726-4f2c-9bff-a39773454702/thumbnail.jpg',
    duration: 24,
    status: 'success',
    user_id: instructor.id,
    created_at: Faker::Time.between(from: 6.months.ago, to: Time.current),
    updated_at: Faker::Time.between(from: 6.months.ago, to: Time.current),
    formats: %w[mp4 hls],
    progress: 100,
    transcription: fetch_transcription_text('https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/cc2fa2bb-7726-4f2c-9bff-a39773454702/transcription/transcript.json'),
    transcription_status: 'completed',
    processing_log: 'Mất chất luôn 🙃 #takhongngu.mp4',
    quality_360p_url: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/cc2fa2bb-7726-4f2c-9bff-a39773454702/hls/360p/playlist.m3u8',
    quality_480p_url: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/cc2fa2bb-7726-4f2c-9bff-a39773454702/hls/480p/playlist.m3u8',
    quality_720p_url: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/cc2fa2bb-7726-4f2c-9bff-a39773454702/hls/720p/playlist.m3u8'
  ),
  Upload.create!(
    id: 'eb44b289-3f1d-4ac3-8090-8849c779b5d4',
    file_type: 'mp4',
    cdn_url: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/eb44b289-3f1d-4ac3-8090-8849c779b5d4/hls/master.m3u8',
    thumbnail_path: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/eb44b289-3f1d-4ac3-8090-8849c779b5d4/thumbnail.jpg',
    duration: 12,
    status: 'success',
    user_id: instructor.id,
    created_at: Faker::Time.between(from: 6.months.ago, to: Time.current),
    updated_at: Faker::Time.between(from: 6.months.ago, to: Time.current),
    formats: %w[mp4 hls],
    progress: 100,
    transcription: fetch_transcription_text('https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/eb44b289-3f1d-4ac3-8090-8849c779b5d4/transcription/transcript.json'),
    transcription_status: 'completed',
    processing_log: 'đém ngược 10 giây.mp4',
    quality_360p_url: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/eb44b289-3f1d-4ac3-8090-8849c779b5d4/hls/360p/playlist.m3u8',
    quality_480p_url: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/eb44b289-3f1d-4ac3-8090-8849c779b5d4/hls/480p/playlist.m3u8',
    quality_720p_url: 'https://e-learning-s3s.s3.ap-southeast-2.amazonaws.com/uploads/eb44b289-3f1d-4ac3-8090-8849c779b5d4/hls/720p/playlist.m3u8'
  )
]

demo_videos = uploads.map(&:cdn_url)
course_thumbnails = uploads.map(&:thumbnail_path)

puts '✅ Created uploads with matching content and thumbnails.'

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
prices = [299_000, 499_000, 999_000, 1_499_000, 1_999_000]

100.times do |i|
  title_index = rand(0..course_titles.length - 1)
  course = Course.create!(
    title: "#{course_titles[title_index]} #{i + 1}",
    description: course_descriptions[title_index],
    price: prices.sample,
    language: languages.sample,
    status: 'published',
    user_id: User.joins(:roles).where(roles: { name: 'instructor' }).sample.id,
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
          is_locked: rand < 0.4 ? Faker::Time.between(from: 6.months.ago, to: Time.current) : nil,
          moderation_status: %i[pending approved rejected locked].sample
        )
      end
    end
  end

  next unless rand < 0.7

  rand(1..5).times do
    student = User.joins(:roles).where(roles: { name: 'student' }).sample
    next if student.nil?
    next if student.enrollments.exists?(course_id: course.id)

    Enrollment.create!(
      user: student,
      course: course,
      status: %i[active pending].sample,
      payment_code: SecureRandom.hex(4).upcase,
      payment_method: Enrollment.payment_method.values.sample,
      amount: course.price,
      paid_at: Faker::Time.between(from: 6.months.ago, to: Time.current),
      enrolled_at: Faker::Time.between(from: 6.months.ago, to: Time.current),
      completed_at: [nil, Faker::Time.between(from: 6.months.ago, to: Time.current)].sample,
      note: ['Completed payment successfully', 'Payment pending', nil].sample
    )
  end
end

puts '✅ Created 100 courses with chapters, lessons, videos and enrollments.'

puts '✅ Created course ratings!'

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

  start_time = Time.current + 5.minutes
  end_time = start_time + 1.hour

  quiz = Quiz.create!(
    title: title,
    is_exam: false,
    time_limit: [10, 15, 20, 25, 30].sample,
    course: course,
    start_time: start_time,
    end_time: end_time
  )

  rand(5..10).times do |j|
    template = question_templates.sample
    content = template.gsub('TOPIC', topic.downcase) + " (##{j + 1})"

    question = Question.create!(
      content: content,
      options: answers.shuffle.each_with_index.map { |v, i| [i.to_s, v] }.to_h,
      correct_option: rand(0..3),
      explanation: "Giải thích chi tiết: #{answers.sample} là phương pháp hiệu quả nhất cho #{topic.downcase}.",
      difficulty: %w[easy medium hard].sample,
      course: course,
      user: course.user,
      topic: %w[math physics chemistry biology history geography literature programming].sample,
      learning_goal: %w[remember understand apply analyze create].sample
    )

    QuizQuestion.create!(quiz: quiz, question: question)
  end

  create_quiz_attempts(quiz, course)

  quiz
end

def create_exam_for_course(course, category_name)
  start_time = Time.current + 5.minutes
  end_time = start_time + 2.hours

  exam = Quiz.create!(
    title: "Bài thi cuối khóa - #{course.title.truncate(30)}",
    is_exam: true,
    time_limit: [30, 45, 60].sample,
    course: course,
    start_time: start_time,
    end_time: end_time
  )

  exam_templates = EXAM_QUESTIONS[category_name] || EXAM_QUESTIONS['Programming']

  rand(15..20).times do |_j|
    template = exam_templates.sample

    subject = template[:content_subjects].sample
    task = template[:content_tasks].sample
    content = "#{template[:content_prefix]}#{subject}#{template[:content_suffix]}#{task}?"

    question = Question.create!(
      content: content,
      options: template[:options].shuffle.each_with_index.map { |v, i| [i.to_s, v] }.to_h,
      correct_option: rand(0..3),
      explanation: "Lý giải chi tiết: #{template[:options].sample} là phương pháp tối ưu cho nhiều trường hợp.",
      difficulty: %w[medium hard].sample,
      course: course,
      user: course.user,
      topic: %w[math physics chemistry biology history geography literature programming].sample,
      learning_goal: %w[remember understand apply analyze create].sample
    )

    QuizQuestion.create!(quiz: exam, question: question)
  end

  exam
end

def create_quiz_attempts(quiz, course)
  return unless course.enrolled_users.any? && rand < 0.8

  students = course.enrolled_users.sample(rand(1..5))

  students.each do |student|
    answers = {}
    correct_count = 0

    quiz.questions.each do |q|
      user_answer = rand(0..3)
      answers[q.id.to_s] = user_answer
      correct_count += 1 if user_answer == q.correct_option
    end

    score = quiz.questions.any? ? (correct_count.to_f / quiz.questions.count * 10).round : 0

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

puts 'Đang tạo bài kiểm tra cho các khóa học'

Course.find_each do |course|
  rand(5..8).times do
    create_quiz_for_course(course, false)
  end

  rand(2..3).times do
    create_quiz_for_course(course, true)
  end
end

puts "✅ Đã tạo #{Quiz.count} bài kiểm tra với #{Question.count} câu hỏi và #{QuizAttempt.count} lần làm bài."

User.joins(:roles).where(roles: { name: 'student' }).each do |student|
  student.enrollments.sample(rand(1..3)).each do |enrollment|
    random_lesson = enrollment.course.chapters.sample&.lessons&.sample
    next unless random_lesson

    Progress.create!(
      user: student,
      course: enrollment.course,
      lesson: random_lesson,
      status: %i[pending inprogress done].sample
    )
  end
end

puts '✅ Created progress records.'

Course.find_each do |course|
  random_rating = rand(3.0..5.0).round(2)
  course.update!(rating: random_rating)
end

puts '✅ Created course ratings!'

puts 'Seeding quiz attempts...'

users = User.all
quizzes = Quiz.all

device_infos = [
  'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36',
  'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1',
  'Mozilla/5.0 (iPad; CPU OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1',
  'Mozilla/5.0 (Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Mobile Safari/537.36'
]

client_ips = [
  '::1',
  '118.69.55.83',
  '192.168.1.1',
  '10.0.0.1',
  '172.16.0.1',
  '127.0.0.1'
]

users.each do |user|
  quizzes.each do |quiz|
    start_time = Time.current - rand(1..24).hours
    completed_at = start_time + rand(10..30).minutes
    time_spent = (completed_at - start_time).to_i

    log_actions = []
    current_time = start_time

    used_devices = Set.new
    used_ips = Set.new

    while current_time < completed_at
      device_info = device_infos.sample
      client_ip = client_ips.sample

      used_devices.add(device_info)
      used_ips.add(client_ip)

      log_actions << {
        client_ip: client_ip,
        timestamp: current_time.iso8601(3),
        device_info: device_info
      }
      current_time += rand(30..180).seconds
    end

    final_device = device_infos.sample
    final_ip = client_ips.sample
    used_devices.add(final_device)
    used_ips.add(final_ip)

    log_actions << {
      client_ip: final_ip,
      timestamp: completed_at.iso8601(3),
      device_info: final_device
    }

    QuizAttempt.create!(
      user: user,
      quiz: quiz,
      score: rand(5..10),
      time_spent: time_spent,
      start_time: start_time,
      completed_at: completed_at,
      tab_switch_count: rand(0..3),
      copy_paste_count: rand(0..2),
      screenshot_count: rand(0..1),
      right_click_count: rand(0..2),
      devtools_open_count: rand(0..1),
      other_unusual_actions: rand(0..2),
      device_count: used_devices.size,
      log_actions: log_actions
    )
  end
end

puts '✅ Created quiz attempts!'
puts "\n🎉 Seed data completed successfully!"
