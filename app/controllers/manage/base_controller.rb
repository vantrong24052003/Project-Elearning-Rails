# frozen_string_literal: true

class Manage::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_manage_access
  layout 'manage'

  private

  def authorize_manage_access
    authorize! :access, :manage_dashboard
  end
end
