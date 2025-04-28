# frozen_string_literal: true

class Dashboard::CartsController < Dashboard::DashboardController
  before_action :authenticate_user!

  def create
    @course = Course.find(params[:course_id])
    @cart_item = current_user.cart_items.new(course: @course)

    if @cart_item.save
      respond_to do |format|
        format.html { redirect_to dashboard_course_path(@course), notice: 'Course added to cart' }
        format.turbo_stream { flash.now[:notice] = 'Course added to cart' }
      end
    else
      respond_to do |format|
        format.html { redirect_to dashboard_course_path(@course), alert: 'Unable to add course to cart' }
        format.turbo_stream { flash.now[:alert] = 'Unable to add course to cart' }
      end
    end
  end

  def destroy
    @cart_item = current_user.cart_items.find(params[:id])
    @cart_item.destroy

    respond_to do |format|
      format.html { redirect_to dashboard_cart_path, notice: 'Course removed from cart' }
      format.turbo_stream { flash.now[:notice] = 'Course removed from cart' }
    end
  end
end
