class AddDemoVideoPathToCourses < ActiveRecord::Migration[8.0]
  def change
    add_column :courses, :demo_video_path, :string
  end
end
