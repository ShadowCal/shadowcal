What's Going On?
===

Rails is magical already, and this package preloads the default Rails 4 setup with plenty of goodies.

# Getting Started

1. Add the following to your .env file:

    PORT=3100
    RACK_ENV=development

2. Run `foreman start` and add the line, similar to the line below, to `config/initializers/devise.rb`:

    config.secret_key = 'd2b22...'

3. Create your heroku app, and push.

# Ingredients

1. General Environment Setup
    - Ruby ~> 2.0.0 specified. (Relies on [RVM](https://rvm.io/))
2. Tweaks for Heroku support
    - [12factor gem](https://github.com/heroku/rails_12factor) for Build/Deploy support.
    - Sqlite database in development (writes to file), PG for production.
    - * Support for Devise/Heroku/Rails4 that doesn't require you to commit compiled assets to git before pushing.
3. Syntactical sugar
    - [HAML](https://github.com/indirect/haml-rails) for lean HTML templates.
    - * [HAMLC / Haml-Coffee-Assets](https://github.com/netzpirat/haml_coffee_assets) for HAML-based templates (via JST) in Javascript support.
    - [SASS](https://github.com/rails/sass-rails) for lean stylesheets and mixin support.
    - [Coffeescript](https://github.com/rails/coffee-rails) for lean javascript.
    - [Squeel gem](https://github.com/activerecord-hackery/squeel) for fancy ActiveRecord syntax.
    -
3. Vendored Assets
    - Javascript
        - jQuery
        - Underscore
        - Backbone
        - jQuery.FancyBox 2.0
        - [Chosen.js](https://github.com/tsechingho/chosen-rails) for nice dropdowns.
    - Stylesheets
        - [Bootstrap-SASS](https://github.com/twbs/bootstrap-sass) for including Bootstrap 3 w. SASS source files. (Lets you use SASS mixins)
        - [Font Awesome](https://github.com/bokmann/font-awesome-rails) glyph icon set.
4. Test Suite Tools
    - [Mocha](https://github.com/quartzmo/mocha_rails) for stubbing and expectations.
    - [FactoryBot] for factories instead of fixtures.
        - TODO: All fixtures have been deleted, but maybe modify generators to not create new ones for new models?
        - * Custom callback skipper for skipping before_/after_/save/create callbacks. *
5. Vendored Ruby Tools
    - [DelayedJob](https://github.com/collectiveidea/delayed_job) for background worker queue.
    - [Devise](https://github.com/plataformatec/devise) for user authentication.
    - [OmniAuth](https://github.com/intridea/omniauth) and [OmniAuth Facebook](https://github.com/mkdynamic/omniauth-facebook) for O-Auth and Facebook Connect support.
    - [make-resourceful](https://github.com/hcatlin/make_resourceful) for mixing prebuilt RESTful support into your controllers.
    - [has-bit-field](https://github.com/pjb3/has-bit-field) to add binary flag-type columns to ActiveRecord models.
    - [RABL](https://github.com/ccocchi/rabl-rails) to add a view layer for JSON responses.
        - Includes [OJ](https://github.com/ohler55/oj) to avoid a bug in Rails 4 between RABL and the default JSON parser.
    - [Paperclip](https://github.com/thoughtbot/paperclip) adds support for uploaded files attached to models.
        - Includes [aws-sdk] to support uploading files directly to your Amazon S3 bucket.
            - Keys sourced from environment variables, configured in ./config/application.rb
    - [Rails Config](https://github.com/railsjedi/rails_config) provides `Settings` object, loaded from `./config/settings.yml`.
    - [rQRCode](https://github.com/whomwah/rqrcode) adds support for generating QR codes in HTML.
    - [ActiveAdmin](https://github.com/gregbell/active_admin) adds support for backend admin panel.


* Custom Things
- vendor/assets/javascript/view_helpers.js.coffee
- assets/javscript/application.js.coffee
    - Backbone includes
    - init.js
    - B
