# frozen_string_literal: true

namespace :app do
  desc "Ping servers so Heroku does not idle them."
  task keepalive: :environment do
    require "net/http"
    require "uri"

    uri = URI.parse("http://example.com")
    Net::HTTP.get_response(uri)
  end
end
