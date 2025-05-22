# frozen_string_literal: true

class GeminiServices
  MAX_RETRIES = 3
  RETRY_DELAY = 2

  def initialize(model: Rails.configuration.x.gemini[:default_model])
    @model = model
    @connection = Faraday.new do |f|
      f.request :json
      f.response :json, content_type: /\bjson$/
    end
  end

  def generate(prompt:, options: {})
    retry_count = 0
    begin
      body = build_request(prompt, options)
      endpoint = format(Rails.configuration.x.gemini[:endpoint_template], model: @model)
      response = @connection.post(endpoint) do |req|
        req.params['key'] = Rails.configuration.x.gemini[:api_key]
        req.headers['Content-Type'] = 'application/json'
        req.body = body
      end
      parse_response(response)
    rescue Faraday::ClientError => e
      if e.response && e.response[:status] == 429 && retry_count < MAX_RETRIES
        retry_count += 1
        sleep RETRY_DELAY
        retry
      else
        raise
      end
    end
  end

  def generate_quiz(title:, description:, num_questions:, difficulty: nil, topic: nil, learning_goal: nil)
    difficulty_level = difficulty.presence
    selected_topic = topic.presence
    selected_learning_goal = learning_goal.presence

    prompt = <<~PROMPT
      Bạn là một chuyên gia tạo đề trắc nghiệm với 50 năm kinh nghiệm, chuyên xây dựng câu hỏi dựa trên mô tả nội dung bài học.

      Thông tin đầu vào:
      - Tiêu đề bài học: #{title}
      - Mô tả nội dung: #{description}
      - Số lượng câu hỏi: #{num_questions}
      - Mức độ: #{difficulty_level}
      - Chủ đề: #{selected_topic}
      - Mục tiêu học tập: #{selected_learning_goal}

      Hãy tạo #{num_questions} câu hỏi trắc nghiệm theo định dạng JSON với schema sau:
      {
        "content": "Nội dung câu hỏi?",
        "options": {
          "0": "Lựa chọn A",
          "1": "Lựa chọn B",
          "2": "Lựa chọn C",
          "3": "Lựa chọn D"
        },
        "correct_option": 1,
        "explanation": "Giải thích vì sao đáp án đúng.",
        "difficulty": "#{difficulty_level}",
        "topic": "#{selected_topic || 'other'}",
        "learning_goal": "#{selected_learning_goal || 'other'}"
      }

      QUAN TRỌNG: Hãy trả về JSON thuần túy, KHÔNG sử dụng định dạng Markdown hay ```json, chỉ trả về mảng JSON không có định dạng bổ sung.

      Kết quả trả về phải là một mảng JSON gồm các object câu hỏi, không kèm bất kỳ nội dung mô tả, nhận xét hay chú thích nào khác ngoài chính mảng JSON đó.
      Ưu tiên tạo câu hỏi dựa trên mô tả 
      Tất cả câu hỏi phải liên quan chặt chẽ đến mô tả nội dung bài học.
      Trả về CHÍNH XÁC định dạng JSON mà không có văn bản giới thiệu hoặc kết luận.
      Đảm bảo câu hỏi được tạo ra là đúng với mức độ khó được yêu cầu.
      Nếu không tạo được câu hỏi, hãy trả về mảng rỗng Nếu thiếu description.
      Đảm bảo không generate những câu hỏi liên quan đến phản động, bạo lực,...
      Hoàng Sa và Trường Sa là của Việt Nam.
    PROMPT

    options = {
      temperature: 0.7,
      max_output_tokens: 1024
    }

    response = generate(prompt: prompt, options: options)
    JSON.parse(response)
  end

  def analyze_and_improve_video_lesson(title:, transcription:, duration:, course_overview: {})
    course_title = course_overview[:title] || 'N/A'
    course_description = course_overview[:description] || 'N/A'
    course_language = course_overview[:language] || 'N/A'
    course_rating = course_overview[:rating] || '0.0'
    course_is_free = course_overview[:is_free] ? 'Có' : 'Không'
    course_price = course_overview[:price] || '0.0'
    course_category = course_overview[:category_name] || 'N/A'

    prompt = <<~PROMPT
      Bạn là chuyên gia phát triển nội dung giáo dục với hơn 20 năm kinh nghiệm tối ưu hóa bài giảng số.

      Nhiệm vụ:
      - Phân tích chất lượng nội dung video bài giảng dựa trên dữ liệu được cung cấp.
      - Đưa ra đề xuất cải thiện để nâng cao chất lượng truyền đạt và hiệu quả học tập.

      Thông tin tổng quan khóa học:
      - Tiêu đề khóa học: #{course_title}
      - Mô tả khóa học: #{course_description}
      - Ngôn ngữ: #{course_language}
      - Đánh giá trung bình: #{course_rating}
      - Khóa học miễn phí: #{course_is_free}
      - Giá: #{course_price}
      - Danh mục: #{course_category}

      Thông tin video bài giảng:
      - Tiêu đề video: #{title}
      - Bản chép lời: #{transcription}
      - Độ dài video (giây): #{duration}

      Yêu cầu phân tích:
      1. Độ phủ nội dung: Nội dung có bao quát đầy đủ và phù hợp với khóa học không?
      2. Cấu trúc bài giảng:#{' '}
        - Nội dung có trình tự hợp lý không (mở bài - thân bài - kết luận)?
        - Các phần có được phân đoạn rõ ràng không?
        - Có sử dụng ví dụ, minh họa, sơ đồ hoặc điểm nhấn để làm rõ nội dung không?
      3. Độ dài: Video có quá dài, quá ngắn hay phù hợp với nội dung?
      4. Ngôn ngữ: Ngôn từ có phù hợp với trình độ người học không? (học thuật / đời thường / dễ hiểu / phức tạp)

      Sau khi phân tích, vui lòng đề xuất cải tiến nội dung theo định dạng JSON sau:

      {
        "analysis": {
          "coverage": "Đánh giá mức độ bao phủ nội dung...",
          "structure": "Đánh giá cấu trúc trình bày...",
          "length": "Đánh giá độ dài...",
          "language": "Đánh giá ngôn ngữ sử dụng..."
        },
        "recommendations": {
          "remove": ["Các phần nên rút gọn hoặc loại bỏ"],
          "add": ["Phần nên bổ sung thêm (ví dụ, ví dụ minh họa, sơ đồ, hình ảnh...)"],
          "restructure": ["Gợi ý tái cấu trúc nếu cần"],
          "notes": "Lưu ý khác để cải thiện chất lượng video bài giảng"
        }
      }

      QUAN TRỌNG:
      - Trả về duy nhất một JSON như định dạng trên, không kèm đoạn văn hay markdown.
      - Nếu thiếu hoặc rỗng phần transcription thì trả về null.
      - Không đề xuất nội dung nhạy cảm, phản cảm hoặc sai lệch.
      - Hoàng Sa và Trường Sa là của Việt Nam.
    PROMPT

    options = {
      temperature: 0.5,
      max_output_tokens: 1024
    }

    response = generate(prompt: prompt, options: options)
    JSON.parse(response)
  end

  private

  def build_request(prompt, options = {})
    content = build_content(prompt)

    request = {
      contents: [content]
    }

    request[:tools] = options[:tools] if options[:tools].present?

    if options[:temperature].present? || options[:top_p].present? || options[:top_k].present? || options[:max_output_tokens].present?
      request[:generationConfig] = {}
      request[:generationConfig][:temperature] = options[:temperature] if options[:temperature].present?
      request[:generationConfig][:topP] = options[:top_p] if options[:top_p].present?
      request[:generationConfig][:topK] = options[:top_k] if options[:top_k].present?
      if options[:max_output_tokens].present?
        request[:generationConfig][:maxOutputTokens] =
          options[:max_output_tokens]
      end
    end

    request
  end

  def build_content(prompt)
    case prompt
    when String
      {
        role: 'user',
        parts: [{ text: prompt }]
      }
    when Hash
      prompt
    when Array
      {
        role: 'user',
        parts: prompt.map { |p| p.is_a?(Hash) ? p : { text: p.to_s } }
      }
    else
      {
        role: 'user',
        parts: [{ text: prompt.to_s }]
      }
    end
  end

  def parse_response(response)
    raise "Gemini API error: #{response.status}" if response.status != 200

    body = response.body

    raise "Gemini API error: #{body['error']['message']}" if body['error'].present?

    if body['candidates'].present? && body['candidates'].first['content'].present?
      content = body['candidates'].first['content']

      if content['parts'].present?
        text_parts = content['parts'].map { |part| part['text'] }.compact
        result = text_parts.join("\n")

        result = result.gsub(/```json\n?/, '').gsub(/```\n?/, '')
        return result
      end

      content
    end
  end
end
