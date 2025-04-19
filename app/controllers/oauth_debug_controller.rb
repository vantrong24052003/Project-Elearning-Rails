# frozen_string_literal: true

class OauthDebugController < ApplicationController
  def check_callback
    # This simply generates the proper callback URL for reference
    google_callback_url = user_google_oauth2_omniauth_callback_url
    google_callback_path = user_google_oauth2_omniauth_callback_path

    render plain: "Google OAuth callback URL should be: #{google_callback_url}\nPath: #{google_callback_path}"
  end
end
