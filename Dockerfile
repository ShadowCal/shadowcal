# Use the barebones version of Ruby 2.2.3.
FROM starefossen/ruby-node:2-8-slim

# Optionally set a maintainer name to let people know who made this image.
MAINTAINER Jordan Feldstein <jfeldstein@gmail.com>

# Install binary dependencies:
# - build-essential: To ensure certain gems can be compiled
# - nodejs: Compile assets
# - libpq-dev: Communicate with postgres through the postgres gem
# - postgresql-client-9.4: In case you want to talk directly to postgres
RUN apt-get update && apt-get install -qq -y \
	build-essential \
	curl \
	libpq-dev \
	git \
	tzdata \
	--fix-missing

# CONFIG
ARG PORT
ARG RACK_ENV
ARG APP_PATH

# App
RUN mkdir -p $APP_PATH
COPY ./Gemfile $APP_PATH
COPY ./vendor $APP_PATH/vendor
WORKDIR $APP_PATH
RUN bundle install --without=test
RUN bundle package --all

COPY . .
# VOLUME ["$APP_PATH/public"]

ENTRYPOINT ["bundle", "exec"]

RUN bundle exec rake RAILS_ENV=$RACK_ENV DATABASE_URL=postgresql://user:pass@127.0.0.1/dbname SECRET_TOKEN=f098CY897WS4FT9J8A0VW378AIOCUWRSYFWBO39N8Y assets:precompile
#CMD bundle exec rails server -p $PORT -e $RACK_ENV