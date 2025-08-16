# frozen_string_literal: true

module AccountSecurity
  extend ActiveSupport::Concern

  private

  def check_locked_account
    if current_user && current_user.reload.locked_at.present?
      sign_out current_user
      reset_session
      redirect_to new_user_session_path, alert: 'Account is locked. Please contact support.'
    end
  end
end
