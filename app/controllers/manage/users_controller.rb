# frozen_string_literal: true

class Manage::UsersController < Manage::BaseController
  before_action :set_user, only: %i[show edit update destroy]
  before_action :authorize_admin

  def index
    @users = User.includes(:roles).where.not(id: User.with_role(:admin).pluck(:id))
    if params[:search].present?
      @users = @users.where('name ILIKE ? OR email ILIKE ?', "%#{params[:search]}%",
                            "%#{params[:search]}%")
    end
    @users = @users.joins(:roles).where(roles: { name: params[:role] }) if params[:role].present?
    @users = @users.where(instructor_request_status: params[:instructor_status]) if params[:instructor_status].present?

    case params[:lock_status]
    when 'locked'
      @users = @users.where.not(locked_at: nil)
    when 'active'
      @users = @users.where(locked_at: nil)
    end

    @users = @users.page(params[:page]).per(params[:per_page] || 10)
  end

  def show; end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to manage_user_path(@user), notice: 'User was successfully created'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if params[:action_type].present?
      handle_instructor_action
      redirect_to manage_users_path, notice: "User was successfully #{params[:action_type]}"
    elsif params[:lock_action].present?
      handle_lock_action
      redirect_to manage_users_path, notice: "User was successfully #{params[:lock_action]}"
    elsif @user.update(user_params)
      handle_instructor_status_update
      redirect_to manage_user_path(@user), notice: 'User was successfully updated'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
    redirect_to manage_users_path, notice: 'User was successfully deleted'
  end

  private

  def authorize_admin
    redirect_to manage_root_path, alert: 'You are not authorized to access this page' unless current_user.has_role?(:admin)
  end

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email, :name, :instructor_request_status)
  end

  def handle_instructor_status_update
    return unless @user.instructor_request_status_changed?

    case @user.instructor_request_status
    when 'approved'
      @user.add_role(:instructor)
      @user.update(instructor_reviewed_at: Time.current)
      UserMailer.instructor_status_notification(@user).deliver_later
    when 'rejected'
      @user.update(instructor_reviewed_at: Time.current)
      UserMailer.instructor_status_notification(@user).deliver_later
    end
  end

  def handle_instructor_action
    case params[:action_type]
    when 'approved'
      @user.update(instructor_request_status: 'approved')
      @user.add_role(:instructor)
      @user.update(instructor_reviewed_at: Time.current)
      UserMailer.instructor_status_notification(@user).deliver_later
    when 'rejected'
      @user.update(instructor_request_status: 'rejected', instructor_reviewed_at: Time.current)
      UserMailer.instructor_status_notification(@user).deliver_later
    end
  end

  def handle_lock_action
    case params[:lock_action]
    when 'locked'
      @user.update(locked_at: Time.current)
    when 'unlocked'
      @user.update(locked_at: nil)
    end
  end
end
