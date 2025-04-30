# frozen_string_literal: true

class Dashboard::ProfilesController < Dashboard::DashboardController
  before_action :authenticate_user!
  before_action :set_user, only: %i[show update]
  before_action :ensure_owner, only: %i[update]

  def show
    if @user.has_role?(:admin) || @user.has_role?(:instructor)
      @courses = @user.courses.includes(:categories) # Sử dụng :categories thay vì :category
    else
      @enrollments = @user.enrollments.includes(course: :categories).where(status: 'active')
    end
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

  private

  def set_user
    @user = params[:id] ? User.find(params[:id]) : current_user
  end

  def ensure_owner
    return if @user == current_user

    redirect_to dashboard_profile_path(current_user), alert: 'You are not authorized to perform this action.'
    false
  end

  def user_params
    params.require(:user).permit(:name, :avatar, :bio, :phone, :address)
  end
end
