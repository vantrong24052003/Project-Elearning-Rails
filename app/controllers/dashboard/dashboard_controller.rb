# frozen_string_literal: true

module Dashboard
  class DashboardController < ApplicationController
    before_action :authenticate_user!
  end
end
