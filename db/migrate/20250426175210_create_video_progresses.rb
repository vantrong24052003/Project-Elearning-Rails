# frozen_string_literal: true

class CreateVideoProgresses < ActiveRecord::Migration[8.0]
  def change
    create_table :video_progresses, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :video, null: false, foreign_key: true, type: :uuid
      t.boolean :watched
      t.datetime :watched_at

      t.timestamps
    end
  end
end
