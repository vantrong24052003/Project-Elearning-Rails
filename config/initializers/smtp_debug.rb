if Rails.env.development?
  # Enable SMTP debugging
  ActionMailer::Base.smtp_settings[:debug_output] = STDOUT

  # Add a test method to verify mail sending
  ActionMailer::Base.class_eval do
    def self.test_mail
      mail = Mail.new do
        from     Rails.application.credentials.dig(:email, :user)
        to       Rails.application.credentials.dig(:email, :user)
        subject  'Test Email'
        body     'This is a test email to verify SMTP connectivity'
      end
      mail.deliver
    end
  end
end
