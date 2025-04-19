class UserMailer < ApplicationMailer
  def welcome_email
    @user = params[:user]
    @token = params[:token]
    @confirm_link = user_confirmation_url(
      confirmation_token: @token,
      host: Rails.application.config.action_mailer.default_url_options[:host]
    )
    mail(to: @user.email, subject: 'Welcome! Confirm your email') # send email chào mừng kèm nút confirm_link ở trong views/user_mailer/welcome_email.html.slim
  end

  # Gửi cho người bị report (tác giả bài viết)
  def reported_notification_email
    @user = params[:user]
    @post = params[:post]
    @reporter = params[:reporter]
    mail(to: @user.email, subject: 'Bài viết của bạn đã bị report')
  end

  # Gửi cho admin
  def admin_report_notification_email
    @user = params[:user]
    @post = params[:post]
    @reporter = params[:reporter]
    mail(to: 'trongdn2405@gmail.com', subject: 'Có bài viết bị report')
  end
end
