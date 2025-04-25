# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    def create
      super do |resource|
        unless resource.persisted?
          flash[:alert] = 'Login failed! Please check your email and password.'
          return redirect_to new_session_path(resource_name)
        end
      end
    end

    def after_sign_in_path_for(resource)
      if resource.has_role?(:admin)
        manage_courses_path
      elsif resource.has_role?(:instructor)
        dashboard_instructor_courses_path
      else
        root_path
      end
    end
  end
end
