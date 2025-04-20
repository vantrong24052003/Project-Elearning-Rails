# frozen_string_literal: true

module ExceptionHandler
  extend ActiveSupport::Concern
  included do
    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :handle_invalid_record
    rescue_from ActiveRecord::RecordNotUnique, with: :handle_not_unique
    rescue_from CanCan::AccessDenied, with: :handle_unauthorized
    rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid
  end

  private

  def handle_exception(e)
    Rails.logger.error(e.message)
    Rails.logger.error(e.backtrace.join("\n"))
    Sentry.capture_exception(e) if Rails.env.production?

    respond_to do |format|
      format.html { render 'errors/500', status: 500, layout: 'error' }
      format.json { render json: { error: 'Internal Server Error' }, status: 500, layout: 'error' }
    end
  end

  def handle_not_found(_e)
    respond_to do |format|
      format.html { render 'errors/404', status: :not_found, layout: 'error' }
      format.json { render json: { error: 'Resource not found' }, status: :not_found, layout: 'error' }
    end
  end

  def handle_unauthorized(_e)
    respond_to do |format|
      format.html do
        flash[:error] = 'Bạn không có quyền thực hiện hành động này'
        redirect_to root_path
      end
      format.json { render json: { error: 'Unauthorized' }, status: :forbidden }
    end
  end

  def handle_record_invalid(e)
    flash[:alert] = "Dữ liệu không hợp lệ: #{e.record.errors.full_messages.join(', ')}"
    redirect_back fallback_location: root_path
  end
end
