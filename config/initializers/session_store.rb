# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

if Rails.env.production?
  ShadowCal::Application.config.session_store :cookie_store,
                                              key:    "_ShadowCal_session",
                                              domain: 'shadowcal.com'
else
  ShadowCal::Application.config.session_store :cookie_store,
                                              key:    "_ShadowCal_session",
                                              domain: :all
end
