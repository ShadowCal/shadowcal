# frozen_string_literal: true

require File.expand_path("../boot", __FILE__)

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module ShadowCal
  class Application < Rails::Application
    config.secret_key_base = "dfd0019257fdec152b3f5d35e5532b4adfd91e3b6ba2d3c3451c9600aa932a79de85b2034afb7eebb2ca5821bdcebdd37d3fd33e9cd462896f5624bac178ed70"

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.autoload_paths += %W[#{config.root}/lib]

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.i18n.enforce_available_locales = false
    I18n.config.enforce_available_locales = false

    config.active_job.queue_adapter = :delayed_job
  end
end
