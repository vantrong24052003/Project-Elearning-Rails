# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def instructor_status_notification(user)
    @user = user
    @status = user.instructor_request_status
    @status_text = case @status
                   when 'approved' then 'đã được chấp thuận'
                   when 'rejected' then 'đã bị từ chối'
                   when 'pending' then 'đang chờ xét duyệt'
                   end

    mail(
      to: @user.email,
      subject: 'Thông báo trạng thái yêu cầu làm Instructor',
      template_path: 'mailers'
    )
  end
end
