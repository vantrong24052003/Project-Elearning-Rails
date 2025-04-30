# frozen_string_literal: true

class Dashboard::ProfilesController < Dashboard::DashboardController
  before_action :authenticate_user!
  before_action :set_user, only: %i[show update]

  def show
    if @user.has_role?(:admin) || @user.has_role?(:instructor)
      @courses = @user.courses.includes(:categories)
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

  def user_params
    params.require(:user).permit(:name, :avatar, :bio, :phone, :address)
  end
end
