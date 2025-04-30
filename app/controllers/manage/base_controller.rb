# frozen_string_literal: true

class Manage::BaseController < ApplicationController
  layout 'manage'
  before_action :authenticate_user!
end
