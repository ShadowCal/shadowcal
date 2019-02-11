# frozen_string_literal: true

ruby "2.3.5"

source "https://rubygems.org"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "4.2.10"

# Use sqlite3 as the database for Active Record
group :development do
  gem "rb-readline"
  gem "sqlite3"
end
group :production do
  gem "pg", '~>0.20.0'
end

gem "rails_12factor", group: :production

# Use SCSS for stylesheets
gem "sass-rails"

# Use Uglifier as compressor for JavaScript assets
gem "uglifier", ">= 1.3.0"

# Use CoffeeScript for .js.coffee assets and views
gem "coffee-rails", "~> 4.0.0"

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem "jquery-rails"
# With Underscore support
gem "underscore-rails"

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem "turbolinks"

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder", "~> 1.2"
gem "json", "1.8.3"

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem "sdoc", require: false
end

group :test do
  gem "mocha"
end

group :development, :test do
  gem "factory_bot_rails", "~> 4.0"

  gem "capybara"
  gem "capybara-screenshot"
  gem "database_cleaner"
  gem "rspec-rails"

  gem "better_errors"
  gem "binding_of_caller"
  gem "faker"

  gem "rspec_junit_formatter"

  gem "webmock"

  gem 'guard-rspec', require: false
end

# Use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.1.2'

# Use unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]

gem "delayed_job_active_record"

gem "devise"
gem "omniauth"
gem "omniauth-google-oauth2"
gem "omniauth-microsoft-office365"
gem "ruby_outlook", github: 'jfeldstein/ruby_outlook', branch: :master

gem "execjs"
gem "haml-rails"
gem "haml_coffee_assets"

gem "bootstrap", "~> 4.0.0.beta2"
gem "sprockets", ">= 3.7.2"
gem "sprockets-rails"

gem "make_resourceful"

gem "has-bit-field"

gem "rollbar"

gem "oj"
gem "rabl"

# Paperclip with the aws sdk
gem "aws-sdk"

gem "backbone-rails"
gem "chosen-rails"
gem "fancybox2-rails", "~> 0.2.4"
gem "font-awesome-rails"
gem "rails_config"

gem "rqrcode"

gem "quiet_assets"

gem "google-api-client", require: "google/apis/calendar_v3"

gem "rubocop", require: false
