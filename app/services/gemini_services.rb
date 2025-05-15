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

  private

  def build_request(prompt, options = {})
    content = build_content(prompt)

    request = {
      contents: [content]
    }

    # Add tools if provided
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
