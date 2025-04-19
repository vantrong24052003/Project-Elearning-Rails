class Users::RegistrationsController < Devise::RegistrationsController
  # You can override Devise methods here if needed

  private

  # Example: Customize the redirect path after sign up
  def after_sign_up_path_for(resource)
    stored_location_for(resource) || root_path
  end

  # Example: Customize the redirect path after account update
  def after_update_path_for(resource)
    edit_user_registration_path
  end
end
