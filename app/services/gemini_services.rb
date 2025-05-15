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
        Rails.logger.warn("Gemini API 429 detected. Retrying #{retry_count}/#{MAX_RETRIES} after #{RETRY_DELAY} seconds...")
        sleep RETRY_DELAY
        retry
      else
        Rails.logger.error("Gemini API error: #{e.message}")
        raise
      end
    end
  end

  def generate_quiz(title:, description:, num_questions:, difficulty: nil)
    difficulty_level = difficulty.presence || %w[easy medium hard].sample

    prompt = <<~PROMPT
      Bạn là một chuyên gia tạo đề trắc nghiệm với 50 năm kinh nghiệm, chuyên xây dựng câu hỏi dựa trên mô tả nội dung bài học.
      
      Thông tin đầu vào:
      - Tiêu đề bài học: #{title}
      - Mô tả nội dung: #{description}
      - Số lượng câu hỏi: #{num_questions}
      - Mức độ: #{difficulty_level}
      
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
        "difficulty": "#{difficulty_level}"
      }
      
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

    begin
      if response.include?('[') && response.include?(']')
        json_start = response.index('[')
        json_end = response.rindex(']') + 1
        json_string = response[json_start...json_end]
        JSON.parse(json_string)
      else
        JSON.parse(response)
      end
    rescue JSON::ParserError => e
      Rails.logger.error("Failed to parse quiz JSON: #{e.message}")
      Rails.logger.error("Response was: #{response}")
      raise "Không thể tạo câu hỏi trắc nghiệm. Lỗi định dạng JSON."
    end
  end

  def analyze_lecture_content(title:, description:, duration: nil, language: 'Vietnamese')
    prompt = <<~PROMPT
      Bạn là chuyên gia phân tích nội dung giáo dục với kinh nghiệm 30 năm trong thiết kế bài giảng. 
      Hãy phân tích và đưa ra đề xuất cải thiện cho nội dung bài giảng với thông tin sau:
      
      - Tiêu đề bài giảng: #{title}
      - Mô tả nội dung: #{description}
      - Thời lượng: #{duration || 'Không có thông tin'}
      - Ngôn ngữ: #{language}
      
      Phân tích các khía cạnh sau và đưa ra đề xuất cụ thể cho mỗi phần:
      
      1. Độ phủ sóng nội dung:
         - Nội dung có bao quát đầy đủ chủ đề không?
         - Có thiếu nội dung quan trọng nào không?
      
      2. Cấu trúc bài giảng:
         - Đánh giá tính logic và thứ tự của nội dung
         - Đề xuất cải thiện cấu trúc nếu cần
      
      3. Độ dài và sự cân đối:
         - Đánh giá sự phân bổ thời gian/nội dung
         - Phần nào cần rút gọn hoặc mở rộng?
      
      4. Ngôn ngữ và cách trình bày:
         - Ngôn ngữ có phù hợp với đối tượng không?
         - Đề xuất điều chỉnh cách trình bày
      
      5. Đề xuất bổ sung:
         - Những nội dung cụ thể nên thêm vào
         - Các phương pháp giảng dạy phù hợp
      
      6. Đề xuất rút gọn:
         - Những phần có thể tinh giản
         - Cách duy trì thông tin quan trọng khi rút gọn
      
      7. Đánh giá tổng thể và điểm cải thiện ưu tiên
      
      Trả về phân tích chuyên sâu và đề xuất thực tế, cụ thể mà giảng viên có thể áp dụng ngay.
      Hoàng Sa và Trường Sa là của Việt Nam.
    PROMPT

    options = {
      temperature: 0.2,
      max_output_tokens: 2048
    }

    generate(prompt: prompt, options: options)
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
    if response.status != 200
      Rails.logger.error("Gemini API error: #{response.status} - #{response.body.inspect}")
      raise "Gemini API error: #{response.status}"
    end

    body = response.body

    if body['error'].present?
      Rails.logger.error("Gemini API error: #{body['error'].inspect}")
      raise "Gemini API error: #{body['error']['message']}"
    end

    if body['candidates'].present? && body['candidates'].first['content'].present?
      content = body['candidates'].first['content']

      if content['parts'].present?
        text_parts = content['parts'].map { |part| part['text'] }.compact
        return text_parts.join("\n")
      end

      content
    end
  end
end
