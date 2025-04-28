# frozen_string_literal: true

class Dashboard::ProfilesController < Dashboard::DashboardController
  before_action :authenticate_user!
  before_action :set_user, only: %i[show update change_password]
  before_action :ensure_owner, only: %i[update change_password]

  def show
    @enrollments = current_user.enrollments.includes(:course)
  end

  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to dashboard_profile_path(@user), notice: 'Profile was successfully updated.' }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :show, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def change_password
    if @user.update_with_password(password_params)
      bypass_sign_in(@user)
      redirect_to dashboard_profile_path(@user), notice: 'Password was successfully changed.'
    else
      flash.now[:alert] = 'Failed to change password.'
      render :show
    end
  end

  private

  def set_user
    @user = current_user
  end

  def ensure_owner
    return if @user == current_user

    redirect_to dashboard_profile_path(current_user), alert: 'You are not authorized to perform this action.'
    false
  end

  def user_params
    # Loại bỏ marketing_emails vì nó không có trong schema
    params.require(:user).permit(:name, :avatar, :bio, :phone, :address)
  end

  def password_params
    params.permit(:current_password, :password, :password_confirmation)
  end
end
