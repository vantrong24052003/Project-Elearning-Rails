# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    def create
      self.resource = warden.authenticate(auth_options)

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

    private

    # Example: Customize the redirect path after login
    def after_sign_in_path_for(resource)
      stored_location_for(resource) || root_path
    end

    # Example: Customize the redirect path after logout
    def after_sign_out_path_for(_resource_or_scope)
      new_user_session_path
    end
  end
end
