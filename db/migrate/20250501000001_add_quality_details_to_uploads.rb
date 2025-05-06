class AddQualityDetailsToUploads < ActiveRecord::Migration[8.0]
  def change
    add_column :uploads, :quality_360p_url, :string
    add_column :uploads, :quality_480p_url, :string
    add_column :uploads, :quality_720p_url, :string
  end
end
