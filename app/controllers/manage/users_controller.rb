# frozen_string_literal: true

module Manage
  class UsersController < Manage::BaseController
    before_action :authenticate_user!
    before_action :require_admin
    before_action :set_user, only: %i[show edit update destroy]

    def index
      @users = User.all
    end

    def show
    end

    def edit
    end

    def update
      if @user.update(user_params)
        redirect_to dashboard_admin_user_path(@user), notice: 'User was successfully updated.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @user.destroy
      redirect_to dashboard_admin_users_path, notice: 'User was successfully deleted.'
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:name, :email, :phone, :bio, role_ids: [])
    end

    def require_admin
      return if current_user.has_role?(:admin)

      redirect_to root_path, alert: 'You are not authorized to access this area.'
    end
  end
end
