class AddThumbnailToVideos < ActiveRecord::Migration[8.0]
  def change
    add_column :videos, :thumbnail, :string
  end
end
