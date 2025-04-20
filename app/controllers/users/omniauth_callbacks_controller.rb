# frozen_string_literal: true

module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    before_action :log_auth_details

    def google_oauth2
      handle_auth('Google')
    end

    def google
      handle_auth('Google')
    end

    def failure
      Rails.logger.error "Omniauth failure: #{params.inspect}"
      flash[:alert] = "Authentication failed: #{params[:message] || 'Unknown error'}"
      redirect_to new_user_session_path
    end

    private

    def log_auth_details
      Rails.logger.info "AUTH PATH: #{request.path}"
      Rails.logger.info "AUTH PARAMS: #{params.inspect}"
      Rails.logger.info "AUTH ENV: #{request.env['omniauth.auth'].inspect}" if request.env['omniauth.auth']
    end

    def handle_auth(provider)
      @user = User.from_omniauth(request.env['omniauth.auth'])

      if @user.persisted?
        if @user.sign_in_count == 1
          set_flash_message(:notice, :success, kind: "#{provider} signup") do
            "Welcome to ELearn! Your account has been successfully created with #{provider}."
          end
        else
          set_flash_message(:notice, :success, kind: provider) do
            "Welcome back! You have successfully signed in with #{provider}."
          end
        end

        sign_in_and_redirect @user, event: :authentication
      else
        session["devise.#{provider.downcase}_data"] = request.env['omniauth.auth'].except(:extra)
        flash[:alert] = @user.errors.full_messages.join(', ')
        redirect_to new_user_registration_url
      end
    end
  end
end
