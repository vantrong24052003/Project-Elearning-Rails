# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  def create
    super do |user|
      if user.persisted?
        user.add_role(:student)

        if params[:role_type] == 'instructor'
          user.update_columns(
            instructor_request_status: 'pending',
            instructor_requested_at: Time.current
          )
          UserMailer.instructor_status_notification(user).deliver_later
        end
      end
    end
  end

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: %i[name bio avatar phone address date_of_birth])
  end
end
