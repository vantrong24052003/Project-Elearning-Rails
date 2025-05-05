# frozen_string_literal: true

class Upload < ApplicationRecord
  belongs_to :user

  # Thiết lập giá trị mặc định cho cột formats
  after_initialize :set_default_values, if: :new_record?

  # Chỉ validate các trường này khi video đã được xử lý thành công
  validates :file_type, :cdn_url, :thumbnail_path, :duration, :resolution, presence: true, on: :update, if: :completed?

  enumerize :status, in: %i[pending processing success failed], default: :pending, predicates: true, scope: true

  def completed?
    status == 'success'
  end

  private

  def set_default_values
    self.formats ||= []
  end
end
