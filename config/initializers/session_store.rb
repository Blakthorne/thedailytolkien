# frozen_string_literal: true

# Configure session store with secure settings
# Session expires after 1 week to allow users to stay logged in
Rails.application.config.session_store :cookie_store,
                                       key: "_thedailytolkien_session",
                                       expire_after: 1.week,
                                       httponly: true,
                                       same_site: :lax
# NOTE: Removed 'secure: Rails.env.production?' temporarily
# The secure flag requires HTTPS, and if there's a proxy/SSL issue
# in production, cookies won't be sent, breaking authentication
# Re-enable once production HTTPS is confirmed working
