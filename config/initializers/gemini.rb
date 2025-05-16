# frozen_string_literal: true

Rails.application.config.x.gemini = {
  api_key: Rails.application.credentials.dig(:gemini, :api_key),
  default_model: 'gemini-2.0-pro',
  models: {
    pro: 'gemini-2.0-pro',
    flash: 'gemini-2.0-flash'
  },
  endpoint_template: 'https://generativelanguage.googleapis.com/v1beta/models/%<model>s:generateContent'
}
