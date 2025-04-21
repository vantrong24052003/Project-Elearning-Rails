# frozen_string_literal: true

module Manage
  class BaseController < ApplicationController
    layout 'manage'
    before_action :authenticate_user!
    before_action :require_admin

    private

    def require_admin
      return if current_user&.has_role?(:admin)

      redirect_to root_path, alert: 'You are not authorized to access this area.'
    end
  end
end
