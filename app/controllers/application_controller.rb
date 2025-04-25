# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include ExceptionHandler

  protect_from_forgery with: :null_session

  allow_browser versions: :modern
end
