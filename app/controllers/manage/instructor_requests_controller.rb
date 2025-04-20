# frozen_string_literal: true

module Manage

class InstructorRequestsController < ApplicationController
  def index
    @pending_requests = User.where(instructor_request_status: 'pending')
                          .order(instructor_requested_at: :desc)
                          .page(params[:page]).per(10)

    @approved_requests = User.where(instructor_request_status: 'approved')
                           .order(instructor_reviewed_at: :desc)
                           .limit(10)
                           .page(params[:approved_page])

    @rejected_requests = User.where(instructor_request_status: 'rejected')
                           .order(instructor_reviewed_at: :desc)
                           .limit(10)
                           .page(params[:rejected_page])
  end

  def show
    @user = User.find(params[:id])
  end

  def approve
    @user = User.find(params[:id])

    if @user.pending_instructor_request?
      @user.approve_instructor_request!(current_user)
      redirect_to dashboard_admin_instructor_requests_path, notice: "#{@user.name || @user.email} has been approved as an instructor."
    else
      redirect_to dashboard_admin_instructor_requests_path, alert: "This request cannot be approved."
    end
  end

  def reject
    @user = User.find(params[:id])
    reason = params[:reason]

    if @user.pending_instructor_request?
      @user.reject_instructor_request!(reason, current_user)
      redirect_to dashboard_admin_instructor_requests_path, notice: "Instructor request has been rejected."
    else
      redirect_to dashboard_admin_instructor_requests_path, alert: "This request cannot be rejected."
    end
  end
end
