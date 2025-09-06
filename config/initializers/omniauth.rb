# OAuth Configuration
# Replace these placeholder values with your actual OAuth credentials
# For Google OAuth2: https://console.developers.google.com/

Rails.application.config.middleware.use OmniAuth::Builder do
  # Google OAuth2
  provider :google_oauth2,
           Rails.application.credentials.dig(:google_oauth2, :client_id) || ENV["GOOGLE_CLIENT_ID"],
           Rails.application.credentials.dig(:google_oauth2, :client_secret) || ENV["GOOGLE_CLIENT_SECRET"],
           scope: "email,profile"
end

# OmniAuth configuration
OmniAuth.config.allowed_request_methods = [ :post, :get ]
OmniAuth.config.silence_get_warning = true
