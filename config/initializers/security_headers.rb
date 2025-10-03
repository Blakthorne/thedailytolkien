# frozen_string_literal: true

# Configure security headers for all responses
Rails.application.config.action_dispatch.default_headers.merge!({
  # Prevent page from being displayed in frames (clickjacking protection)
  "X-Frame-Options" => "DENY",

  # Prevent MIME type sniffing
  "X-Content-Type-Options" => "nosniff",

  # Enable XSS protection in older browsers
  "X-XSS-Protection" => "1; mode=block",

  # Control referrer information sent with requests
  "Referrer-Policy" => "strict-origin-when-cross-origin",

  # Permissions Policy (formerly Feature Policy)
  "Permissions-Policy" => "geolocation=(), microphone=(), camera=()"
})

# Content Security Policy
Rails.application.config.content_security_policy do |policy|
  policy.default_src :self, :https
  policy.font_src    :self, :https, :data
  policy.img_src     :self, :https, :data
  policy.object_src  :none
  policy.script_src  :self, :https
  # Allow inline styles (required for existing inline style attributes in views)
  # Note: This is less secure than using nonces or hashes, but required for 377+ inline styles
  policy.style_src   :self, :https, :unsafe_inline

  # Development/Test environment: Allow inline scripts and LiveReload
  # Note: 'unsafe-inline' allows inline onclick handlers and <script> tags in views
  # LiveReload needs http://localhost:35729 and ws:// connections for hot reloading
  if Rails.env.development? || Rails.env.test?
    policy.connect_src :self, :https, "ws://localhost:*", "ws://127.0.0.1:*", "http://localhost:35729", "http://127.0.0.1:35729"
    policy.script_src :self, :https, :unsafe_inline, "http://localhost:35729", "http://127.0.0.1:35729"
  end
end

# Generate CSP nonce for scripts in PRODUCTION ONLY
# In development/test, we use 'unsafe-inline' for flexibility with inline scripts
# When a nonce is present, browsers ignore 'unsafe-inline' per CSP Level 2 spec
# This is why we only generate nonces in production
if Rails.env.production?
  Rails.application.config.content_security_policy_nonce_generator = ->(request) {
    request.session.id.to_s
  }

  # Only apply nonce to script-src, not style-src
  # This prevents the nonce from overriding 'unsafe-inline' for styles
  Rails.application.config.content_security_policy_nonce_directives = %w[script-src]
end

# Report CSP violations (optional - only in production)
if Rails.env.production?
  Rails.application.config.content_security_policy_report_only = false
end
