class Upload < ApplicationRecord
  # Associations
  belongs_to :user

  # Validations
  validates :file_type, :cdn_url, :thumbnail_path, :duration, :resolution, :status, presence: true
end
