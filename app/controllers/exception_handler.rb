# frozen_string_literal: true

module ExceptionHandler
  extend ActiveSupport::Concern
  included do
    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid
    rescue_from ActiveRecord::RecordNotUnique, with: :handle_not_unique
    rescue_from CanCan::AccessDenied, with: :handle_unauthorized
    rescue_from ActiveRecord::InvalidForeignKey, with: :handle_foreign_key_violation
    rescue_from ActionController::BadRequest, with: :handle_bad_request
  end

  private

  def handle_exception(error)
    Sentry.capture_exception(error) if Rails.env.production?

    respond_to do |format|
      format.html { render file: Rails.public_path.join('500.html'), layout: false, status: :internal_server_error }
      format.json { render json: { error: 'Internal Server Error' }, status: :internal_server_error }
    end
  end

  def handle_not_found(_error)
    respond_to do |format|
      format.html { render file: Rails.public_path.join('404.html'), layout: false, status: :not_found }
      format.json { render json: { error: 'Resource not found' }, status: :not_found }
    end
  end

  def handle_unauthorized(_error)
    respond_to do |format|
      format.html do
        flash[:alert] = 'Unauthorized'
        redirect_to root_path
      end
      format.json { render json: { error: 'Unauthorized' }, status: :forbidden }
    end
  end

  def handle_record_invalid(error)
    flash[:alert] = "Invalid data: #{error.record.errors.full_messages.join(', ')}"
    redirect_back fallback_location: root_path
  end

  def handle_not_unique(_error)
    respond_to do |format|
      format.html do
        flash[:alert] = 'Duplicate data. Please check the information again.'
        redirect_back fallback_location: root_path
      end
      format.json do
        render json: { error: 'Duplicate data. Please check the information again.' }, status: :conflict
      end
    end
  end

  def handle_foreign_key_violation(_error)
    respond_to do |format|
      format.html do
        flash[:alert] = 'This item cannot be deleted because it is in use elsewhere.'
        redirect_back fallback_location: root_path
      end
      format.json do
        render json: { error: 'This item cannot be deleted because it is in use elsewhere.' }, status: :conflict
      end
    end
  end

  def handle_bad_request(error)
    respond_to do |format|
      format.html do
        flash[:alert] = error.message
        redirect_back fallback_location: root_path
      end
      format.json do
        render json: { error: error.message }, status: :bad_request
      end
    end
  end
end
