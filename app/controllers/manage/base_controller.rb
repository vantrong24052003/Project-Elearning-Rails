# frozen_string_literal: true

module Manage
  class BaseController < ApplicationController
    layout 'manage'
    before_action :authenticate_user!
    before_action :authorize_admin

    private

    def authorize_admin
      return if current_user&.has_role?(:admin)

      flash[:alert] = 'You are not authorized to access this page'
      redirect_to root_path
    end
  end
end
