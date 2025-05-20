# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  def create
    user = User.find_by(email: params[:user][:email])
    if user&.has_role?(:student)
      super
    else
      flash[:alert] = 'Invalid email or password'
      redirect_to new_user_session_path
    end
  end

  def after_sign_in_path_for(resource)
      root_path
  end
end
