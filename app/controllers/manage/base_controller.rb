# frozen_string_literal: true

class Manage::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_manage_access
  before_action :check_locked_account
  layout 'manage'

  private

  def authorize_manage_access
    authorize! :access, :manage_dashboard
  end

  def check_locked_account
    if current_user && current_user.reload.locked_at.present?
      sign_out current_user
      reset_session
      redirect_to new_user_session_path, alert: "Account is locked. Please contact support."
    end
  end
end
