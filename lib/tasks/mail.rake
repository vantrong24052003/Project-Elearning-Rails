namespace :mail do
  desc 'Test email delivery'
  task test: :environment do
    puts 'Attempting to send a test email...'
    puts "SMTP Settings: #{ActionMailer::Base.smtp_settings.reject { |k, _| k == :password }}"
    puts "Default URL options: #{ActionMailer::Base.default_url_options.inspect}"
    puts "Delivery method: #{ActionMailer::Base.delivery_method}"
    puts "Perform deliveries: #{ActionMailer::Base.perform_deliveries}"
    puts "Raise delivery errors: #{ActionMailer::Base.raise_delivery_errors}"

    begin
      # Create a more specific test mail
      mail = Mail.new do
        from     Rails.application.credentials.dig(:email, :user)
        to       'test@example.com' # Replace with your test email
        subject  'Rails Mailer Test'
        body     "This is a test email from your Rails application at #{Time.current}"
      end

      result = mail.deliver
      puts 'Test email sent!'
      puts "Delivery result: #{result.inspect}"
    rescue StandardError => e
      puts "Error sending email: #{e.message}"
      puts e.backtrace.join("\n")
    end
  end

  desc 'Test Devise mailer specifically'
  task devise_test: :environment do
    puts 'Testing Devise mailer...'

    begin
      # Find or create a test user
      email = 'test@example.com' # Replace with your test email
      user = User.find_by(email: email) || User.new(
        email: email,
        password: 'password123',
        password_confirmation: 'password123'
      )

      # Generate confirmation token if needed
      if user.new_record?
        user.skip_confirmation_notification! if user.respond_to?(:skip_confirmation_notification!)
        user.save!
        puts "Created test user: #{user.email}"
      end

      # Send confirmation instructions directly
      if user.respond_to?(:send_confirmation_instructions)
        result = user.send_confirmation_instructions
        puts "Confirmation email sent: #{result.inspect}"
      else
        puts "User model doesn't support confirmation"
      end

      # Send reset password instructions as a fallback
      if user.respond_to?(:send_reset_password_instructions)
        result = user.send_reset_password_instructions
        puts "Reset password email sent: #{result.inspect}"
      end
    rescue StandardError => e
      puts "Error testing Devise mailer: #{e.message}"
      puts e.backtrace.join("\n")
    end
  end
end
