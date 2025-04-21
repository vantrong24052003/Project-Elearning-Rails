# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    def create
      Rails.logger.debug "Trying to log in with: #{params[:user][:email]}"
      self.resource = warden.authenticate(auth_options)
      Rails.logger.debug "Authentication result: #{resource.inspect}"

      if resource
        set_flash_message!(:notice, :signed_in)
        sign_in(resource_name, resource)
        yield resource if block_given?
        respond_with resource, location: after_sign_in_path_for(resource)
      else
        flash[:alert] = 'Login failed! Please check your email and password.'
        redirect_to new_session_path(resource_name)
      end
    end

    def after_sign_in_path_for(resource)
      if resource.has_role?(:admin)
        manage_users_path || dashboard_root_path
      elsif resource.has_role?(:instructor)
        dashboard_instructor_courses_path || dashboard_root_path
      else
        root_path
      end
    end
  end
end
