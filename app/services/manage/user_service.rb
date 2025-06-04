# frozen_string_literal: true

class Manage::UserService
  def initialize(current_user)
    @current_user = current_user
  end

  def filter_users(params)
    users = User.includes(:roles).where.not(id: User.with_role(:admin).pluck(:id))
    users = users.where('name ILIKE ? OR email ILIKE ?', "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?
    users = users.joins(:roles).where(roles: { name: params[:role] }) if params[:role].present?
    users = users.where(instructor_request_status: params[:instructor_status]) if params[:instructor_status].present?
    case params[:lock_status]
    when 'locked'
      users = users.where.not(locked_at: nil)
    when 'active'
      users = users.where(locked_at: nil)
    end
    users.page(params[:page]).per(params[:per_page] || 10)
  end

  def create_user(user_params)
    User.new(user_params)
  end

  def update_user(user, user_params)
    user.update(user_params)
    user
  end

  def destroy_user(user)
    user.destroy
  end

  def handle_instructor_action(user, action_type)
    case action_type
    when :approved
      user.update(instructor_request_status: :approved)
      user.add_role(:instructor)
      user.update(instructor_reviewed_at: Time.current)
      UserMailer.instructor_status_notification(user).deliver_later
    when :rejected
      user.update(instructor_request_status: :rejected, instructor_reviewed_at: Time.current)
      UserMailer.instructor_status_notification(user).deliver_later
    end
  end

  def handle_lock_action(user, lock_action)
    case lock_action
    when :locked
      user.update(locked_at: Time.current)
    when :unlocked
      user.update(locked_at: nil)
    end
  end

  def handle_instructor_status_update(user)
    return unless user.instructor_request_status_changed?
    case user.instructor_request_status.to_sym
    when :approved
      user.add_role(:instructor)
      user.update(instructor_reviewed_at: Time.current)
      UserMailer.instructor_status_notification(user).deliver_later
    when :rejected
      user.update(instructor_reviewed_at: Time.current)
      UserMailer.instructor_status_notification(user).deliver_later
    end
  end
end 