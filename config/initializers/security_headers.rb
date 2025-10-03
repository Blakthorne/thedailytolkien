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

  # TEMPORARY: Allow unsafe-inline in ALL environments until views are CSP-ready
  # The codebase has extensive inline scripts and event handlers that need refactoring
  # before we can enforce strict CSP with nonces in production
  # TODO: Gradually migrate inline scripts to external files and use nonces
  policy.script_src  :self, :https, :unsafe_inline

  # Allow inline styles (required for existing inline style attributes in views)
  # Note: This is less secure than using nonces or hashes, but required for 377+ inline styles
  policy.style_src   :self, :https, :unsafe_inline

  # Development/Test environment: Add LiveReload connections
  # LiveReload needs http://localhost:35729 and ws:// connections for hot reloading
  if Rails.env.development? || Rails.env.test?
    policy.connect_src :self, :https, "ws://localhost:*", "ws://127.0.0.1:*", "http://localhost:35729", "http://127.0.0.1:35729"
    policy.script_src :self, :https, :unsafe_inline, "http://localhost:35729", "http://127.0.0.1:35729"
  end
end

# NOTE: CSP nonces are disabled until the codebase is prepared for strict CSP
# The nonce system was causing 500 errors in production because:
# 1. Views have inline scripts and event handlers that need nonces
# 2. Not all views were updated to use nonces correctly
# 3. The nonce generator had session dependencies that failed in production
#
# Future work: Implement proper CSP with nonces by:
# 1. Migrating all inline scripts to external files or adding nonces
# 2. Removing all inline event handlers (onclick, onchange, etc.)
# 3. Using event delegation with data attributes
# 4. Testing thoroughly in production-like environment before deployment

# Report CSP violations (optional - only in production)
if Rails.env.production?
  Rails.application.config.content_security_policy_report_only = false
end
