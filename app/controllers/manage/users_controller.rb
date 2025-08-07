# frozen_string_literal: true

class Manage::UsersController < Manage::BaseController
  before_action :set_user, only: %i[show edit update destroy]
  before_action :authorize_admin
  before_action :initialize_user_service

  def index
    @users = @user_service.filter_users(params)
  end

  def show; end

  def new
    @user = User.new
  end

  def create
    @user = @user_service.create_user(user_params)
    if @user.save
      redirect_to manage_user_path(@user), notice: 'User was successfully created'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update  
    if params[:action_type].present?
      @user_service.handle_instructor_action(@user, params[:action_type].to_sym)
      redirect_to manage_users_path, notice: "User was successfully #{params[:action_type]}"
    elsif params[:lock_action].present?
      @user_service.handle_lock_action(@user, params[:lock_action].to_sym)
      notice_msg = params[:lock_action].to_sym == :locked ? 'Account has been locked.' : 'Account has been unlocked.'
      redirect_to manage_users_path, notice: notice_msg
    elsif @user_service.update_user(@user, user_params)
      @user_service.handle_instructor_status_update(@user)
      redirect_to manage_user_path(@user), notice: 'User was successfully updated'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user_service.destroy_user(@user)
    redirect_to manage_users_path, notice: 'User was successfully deleted'
  end

  private

  def authorize_admin
    unless current_user.has_role?(:admin)
      redirect_to manage_root_path,
                  alert: 'You are not authorized to access this page'
    end
  end

  def set_user
    @user = User.find(params[:id])
  end

  def initialize_user_service
    @user_service = Manage::UserService.new(current_user)
  end

  def user_params
    params.require(:user).permit(:email, :name, :instructor_request_status)
  end
end
