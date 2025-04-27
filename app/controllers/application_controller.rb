# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include ExceptionHandler

  protect_from_forgery with: :null_session

  allow_browser versions: :modern

  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.html do
        flash[:alert] = 'You are not authorized to perform this action.'
        redirect_to root_path
      end
      format.json { render json: { error: exception.message }, status: :forbidden }
    end
  end
end
