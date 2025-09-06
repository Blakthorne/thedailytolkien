# OAuth Configuration
# Replace these placeholder values with your actual OAuth credentials
# For Google OAuth2: https://console.developers.google.com/
# For Facebook OAuth: https://developers.facebook.com/

Rails.application.config.middleware.use OmniAuth::Builder do
  # Google OAuth2
  provider :google_oauth2,
           Rails.application.credentials.dig(:google_oauth2, :client_id) || ENV["GOOGLE_CLIENT_ID"] || "your_google_client_id_here",
           Rails.application.credentials.dig(:google_oauth2, :client_secret) || ENV["GOOGLE_CLIENT_SECRET"] || "your_google_client_secret_here",
           scope: "email,profile"

  # Facebook OAuth
  provider :facebook,
           Rails.application.credentials.dig(:facebook, :app_id) || ENV["FACEBOOK_APP_ID"] || "your_facebook_app_id_here",
           Rails.application.credentials.dig(:facebook, :app_secret) || ENV["FACEBOOK_APP_SECRET"] || "your_facebook_app_secret_here",
           scope: "email"
end

# OmniAuth configuration
OmniAuth.config.allowed_request_methods = [ :post, :get ]
OmniAuth.config.silence_get_warning = true
