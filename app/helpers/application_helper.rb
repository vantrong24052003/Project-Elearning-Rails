# frozen_string_literal: true

module ApplicationHelper
  def asset_exists?(path)
    # For Propshaft
    Rails.application.assets.load_path.find(path).present?
  rescue StandardError
    false
  end
end
