# frozen_string_literal: true

module Users
  class PasswordsController < Devise::PasswordsController
    # You can override Devise methods here if needed

    private

    # Example: Customize the redirect path after sending reset password instructions
    def after_sending_reset_password_instructions_path_for(resource_name)
      new_session_path(resource_name)
    end

    # Example: Customize the redirect path after resetting the password
    def after_resetting_password_path_for(resource)
      signed_in_root_path(resource)
    end
  end
end
