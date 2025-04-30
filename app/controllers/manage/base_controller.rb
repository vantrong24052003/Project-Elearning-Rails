# frozen_string_literal: true

module Manage
  class BaseController < ApplicationController
    layout 'manage'
    before_action :authenticate_user!
  end
end
