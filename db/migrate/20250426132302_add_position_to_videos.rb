class AddPositionToVideos < ActiveRecord::Migration[8.0]
  def change
    add_column :videos, :position, :integer
  end
end
