# frozen_string_literal: true

module Users
  class RegistrationsController < Devise::RegistrationsController
    before_action :configure_sign_up_params, only: [:create]
    before_action :configure_account_update_params, only: [:update]

    # POST /resource
    def create
      build_resource(sign_up_params)

      instructor_requested = params[:role_type] == "instructor"

      resource.save

      if resource.persisted?
        resource.add_role(:student)

        if instructor_requested
          resource.update_columns(
            instructor_request_status: "pending",
            instructor_requested_at: Time.current
          )
        end

        if resource.confirmed? || !resource.respond_to?(:confirmed?) || !resource.send(:confirmation_required?)
          set_flash_message! :notice, :signed_up if is_flashing_format?
          sign_up(resource_name, resource)
          respond_with resource, location: after_sign_up_path_for(resource)
        else
          set_flash_message! :notice, :signed_up_but_unconfirmed if is_flashing_format?
          expire_data_after_sign_in!
          respond_with resource, location: after_inactive_sign_up_path_for(resource)
        end
      else
        clean_up_passwords resource
        set_minimum_password_length
        respond_with resource
      end
    end

    protected

    def configure_sign_up_params
      devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    end

    def configure_account_update_params
      devise_parameter_sanitizer.permit(:account_update, keys: [:name, :bio, :avatar, :phone, :address, :date_of_birth])
    end

    def after_sign_up_path_for(resource)
      stored_location_for(resource) || root_path
    end

    def after_inactive_sign_up_path_for(resource)
      new_user_session_path
    end
  end
end
