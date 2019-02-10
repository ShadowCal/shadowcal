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
ARG RAILS_PATH

# App
RUN mkdir -p $RAILS_PATH

# This will cause committing any changes to the rails app to rebundle all the gems. Can't figure out how to only copy over Gemfile, build, and copy ruby_outlook before the rest of `/rails`
COPY ./rails $RAILS_PATH 

WORKDIR $RAILS_PATH
RUN bundle install --without=test
RUN bundle package --all

EXPOSE 80

ENTRYPOINT ["bundle", "exec"]

RUN bundle exec rake RAILS_ENV=$RACK_ENV DATABASE_URL=postgresql://user:pass@127.0.0.1/dbname SECRET_TOKEN=f098CY897WS4FT9J8A0VW378AIOCUWRSYFWBO39N8Y assets:precompile
