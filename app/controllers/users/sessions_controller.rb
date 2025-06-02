# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  def create
    user = User.find_by(email: params[:user][:email])
    if user&.has_role?(:student)
      if user.locked_at.present?
        flash[:alert] = "Account has been locked from #{user.locked_at.strftime('%d/%m/%Y %H:%M')}"
        redirect_to new_user_session_path
      else
        super
      end
    else
      flash[:alert] = 'Invalid email or password'
      redirect_to new_user_session_path
    end
  end

  def after_sign_in_path_for(_resource)
    root_path
  end
end
