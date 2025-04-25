module ApplicationHelper
  def asset_exists?(path)
    begin
      Rails.application.assets_manifest.assets[path].present?
    rescue
      false
    end
  end
end
