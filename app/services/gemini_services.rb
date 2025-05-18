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
