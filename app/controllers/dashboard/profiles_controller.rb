# frozen_string_literal: true

class Dashboard::ProfilesController < Dashboard::DashboardController
  before_action :set_user, only: %i[show update]
  before_action :initialize_profile_service, only: %i[show]

  def show
    user_data = @profile_service.load_user_data
    @courses = user_data[:courses]
    @enrollments = user_data[:enrollments]
  end

  def update
    if @user.update(user_params)
      redirect_to dashboard_profile_path(@user), notice: 'Profile was successfully updated.'
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = params[:id] ? User.find(params[:id]) : current_user
  end

  def initialize_profile_service
    @profile_service = Dashboard::ProfileService.new(@user)
  end

  def user_params
    params.require(:user).permit(:name, :avatar, :bio, :phone, :address)
  end
end
