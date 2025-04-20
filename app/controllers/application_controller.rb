# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include ExceptionHandler

  protect_from_forgery with: :null_session

  allow_browser versions: :modern

  def after_sign_in_path_for(resource)
    resource.has_role?(:admin) ? admin_posts_path : root_path
  end
end
