# frozen_string_literal: true

# Configure session store with secure settings
# Session expires after 1 week to allow users to stay logged in
Rails.application.config.session_store :cookie_store,
                                       key: "_thedailytolkien_session",
                                       expire_after: 1.week,
                                       secure: Rails.env.production?,
                                       httponly: true,
                                       same_site: :lax
