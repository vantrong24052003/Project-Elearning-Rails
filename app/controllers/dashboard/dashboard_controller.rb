# frozen_string_literal: true

class Dashboard::DashboardController < ApplicationController
  include AccountSecurity
  before_action :check_locked_account
end
