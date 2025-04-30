# frozen_string_literal: true

class Dashboard::DashboardController < ApplicationController
  before_action :authenticate_user!
end
