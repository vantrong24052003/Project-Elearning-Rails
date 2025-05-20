class Manage::SessionsController < Devise::SessionsController
  def create
    user = User.find_by(email: params[:user][:email])
    if user&.has_role?(:admin) || user&.has_role?(:instructor)
      if user.locked_at.present?
        flash[:alert] = "Account has been locked from #{user.locked_at.strftime('%d/%m/%Y %H:%M')}"
        redirect_to manage_login_path
      else
      super
        flash[:notice] = 'Login successfully'
      end
    else
      flash[:alert] = 'Invalid email or password'
      redirect_to manage_login_path
    end
  end

  def after_sign_in_path_for(resource)
    manage_root_path
  end
end
