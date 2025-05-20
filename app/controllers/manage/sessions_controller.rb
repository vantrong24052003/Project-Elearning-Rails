class Manage::SessionsController < Devise::SessionsController
  def create
    user = User.find_by(email: params[:user][:email])
    if user&.has_role?(:admin) || user&.has_role?(:instructor)
      super
      flash[:notice] = 'Login successfully'
    else
      flash[:alert] = 'Invalid email or password'
      redirect_to manage_login_path
    end
  end

  def after_sign_in_path_for(resource)
    manage_root_path
  end
end
