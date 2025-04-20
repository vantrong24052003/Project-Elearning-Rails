module Dashboard
  class DashboardController < ApplicationController
    before_action :authenticate_user!

    # Add any common dashboard functionality here
    # This controller serves as the base controller for all dashboard controllers
  end
end
