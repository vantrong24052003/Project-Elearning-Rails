# frozen_string_literal: true

module Users
  class UnlocksController < Devise::UnlocksController
    protected

    def after_unlock_path_for(resource)
      new_session_path(resource) if is_navigational_format?
    end
  end
end
