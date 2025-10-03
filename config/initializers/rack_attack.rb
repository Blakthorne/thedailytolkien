# frozen_string_literal: true

# Configure Rack::Attack for rate limiting and brute force protection
class Rack::Attack
  # Configuration
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  # Always allow requests from localhost in development
  safelist("allow-localhost") do |req|
    req.ip == "127.0.0.1" || req.ip == "::1" if Rails.env.development?
  end

  ### Throttle Configuration ###

  # Throttle login attempts by email address
  # Allows 15 login attempts per email per 5 minutes
  throttle("logins/email", limit: 15, period: 5.minutes) do |req|
    if req.path == "/users/sign_in" && req.post?
      # Extract email from the request parameters
      req.params["user"]&.dig("email")&.downcase&.presence
    end
  end

  # Throttle login attempts by IP address
  # Allows 15 login attempts per IP per 5 minutes
  throttle("logins/ip", limit: 15, period: 5.minutes) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.ip
    end
  end

  # Throttle password reset requests by email
  # Allows 3 password reset attempts per email per hour
  throttle("password_resets/email", limit: 3, period: 1.hour) do |req|
    if req.path == "/users/password" && req.post?
      req.params["user"]&.dig("email")&.downcase&.presence
    end
  end

  # Throttle password reset requests by IP
  # Allows 10 password reset attempts per IP per hour
  throttle("password_resets/ip", limit: 10, period: 1.hour) do |req|
    if req.path == "/users/password" && req.post?
      req.ip
    end
  end

  # Throttle registration attempts by IP
  # Allows 5 registrations per IP per hour
  throttle("registrations/ip", limit: 5, period: 1.hour) do |req|
    if req.path == "/users" && req.post?
      req.ip
    end
  end

  # Throttle comment creation by IP for non-authenticated users
  # Allows 200 comments per IP per hour
  throttle("comments/ip", limit: 200, period: 1.hour) do |req|
    if req.path == "/comments" && req.post?
      req.ip unless req.env["warden"]&.user
    end
  end

  # General API request throttling by IP
  # Allows 500 requests per IP per 5 minutes (approximately 1.67 requests per second)
  throttle("req/ip", limit: 500, period: 5.minutes) do |req|
    req.ip
  end

  ### Custom Response ###

  # Customize the response when throttled
  self.throttled_responder = lambda do |request_env|
    begin
      match_data = request_env["rack.attack.match_data"] || {}
      now = match_data[:epoch_time] || Time.now.to_i
      period = match_data[:period] || 300
      limit = match_data[:limit] || 0

      headers = {
        "RateLimit-Limit" => limit.to_s,
        "RateLimit-Remaining" => "0",
        "RateLimit-Reset" => (now + (period - now % period)).to_s,
        "Content-Type" => "text/html"
      }

      retry_after = period - (now % period)
      headers["Retry-After"] = retry_after.to_s

      discriminator = match_data[:discriminator]
      message = if discriminator.is_a?(String) && discriminator.include?("@")
        "Too many authentication attempts for this account. Please try again later."
      else
        "Too many requests. Please try again later."
      end

      [ 429, headers, [ <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <title>Too Many Requests</title>
          <style>
            body { font-family: system-ui, -apple-system, sans-serif; max-width: 600px; margin: 100px auto; padding: 20px; text-align: center; }
            h1 { color: #d32f2f; }
            p { color: #666; line-height: 1.6; }
          </style>
        </head>
        <body>
          <h1>Rate Limit Exceeded</h1>
          <p>#{message}</p>
          <p>Please wait #{retry_after} seconds before trying again.</p>
        </body>
        </html>
      HTML
      ] ]
    rescue => e
      Rails.logger.error "[Rack::Attack] Error in throttled_responder: #{e.message}\n#{e.backtrace.join("\n")}"

      # Return a fallback response with basic headers
      fallback_headers = {
        "Content-Type" => "text/html",
        "RateLimit-Limit" => "5",
        "RateLimit-Remaining" => "0",
        "RateLimit-Reset" => (Time.now.to_i + 300).to_s,
        "Retry-After" => "300"
      }

      [ 429, fallback_headers, [ "<html><body><h1>Too Many Requests</h1><p>Please try again later.</p></body></html>" ] ]
    end
  end

  ### Logging ###

  # Log blocked requests (disabled in tests to avoid errors)
  unless Rails.env.test?
    ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |name, _start, _finish, _request_id, payload|
      Rails.logger.warn "[Rack::Attack] #{name} - IP: #{payload[:request].ip}" if payload[:request]
    rescue => e
      Rails.logger.error "[Rack::Attack] Logging error: #{e.message}"
    end
  end
end
