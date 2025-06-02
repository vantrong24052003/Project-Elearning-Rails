# frozen_string_literal: true

class ChangeIsLockedToNullableInVideos < ActiveRecord::Migration[8.0]
  def change
    change_column_null :videos, :is_locked, true
  end
end
