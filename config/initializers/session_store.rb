# frozen_string_literal: true

# Explicit session store configuration required for OmniAuth state persistence.
#
# OmniAuth writes `omniauth.state` into env['rack.session'] from Rack middleware,
# outside a normal Rails controller action. Without an explicit config, ActionDispatch
# may not mark the session as modified and skips writing the Set-Cookie header.
# That leaves the callback request with no session cookie → csrf_detected.
#
# SameSite: :lax allows the session cookie to be sent on top-level cross-site
# navigations (e.g. Google redirecting back to /auth/google_oauth2/callback).
# Secure: true is enforced in production only; HTTP localhost needs it off.
Rails.application.config.session_store :cookie_store,
                                       key: '_password_manager_session',
                                       same_site: :lax,
                                       secure: Rails.env.production?
