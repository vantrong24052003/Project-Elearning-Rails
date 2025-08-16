# frozen_string_literal: true

class Manage::BaseController < ApplicationController
  include AccountSecurity
  before_action :check_locked_account
  before_action :authenticate_user!
  before_action :authorize_manage_access
  layout 'manage'

  private

  def authorize_manage_access
    authorize! :access, :manage_dashboard
  end


end
