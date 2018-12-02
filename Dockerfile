# Use the barebones version of Ruby 2.2.3.
FROM starefossen/ruby-node:2-8-slim

# Optionally set a maintainer name to let people know who made this image.
MAINTAINER Jordan Feldstein <jfeldstein@gmail.com>

# Install dependencies:
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

# Install node 8.x
#RUN curl -sL https://deb.nodesource.com/setup_8.x | bash
#RUN apt-get install nodejs


# Set an environment variable to store where the app is installed to inside
# of the Docker image.
ENV INSTALL_PATH /shadowcal
RUN mkdir -p $INSTALL_PATH

# This sets the context of where commands will be ran in and is documented
# on Docker's website extensively.
WORKDIR $INSTALL_PATH

# Ensure gems are cached and only get updated when they change. This will
# drastically increase build times when your gems do not change.
COPY Gemfile Gemfile
RUN bundle install

ENTRYPOINT ["bundle", "exec"]

# Copy in the application code from your work station at the current directory
# over to the working directory.
COPY . .

# Provide dummy data to Rails so it can pre-compile assets.
RUN rake RAILS_ENV=production DATABASE_URL=postgresql://user:pass@127.0.0.1/dbname SECRET_TOKEN=f0398CY897WS4FT9J8A0VW378AIOCUWRSYFWBO39N8Y assets:precompile

# Expose a volume so that nginx will be able to read in assets in production.
VOLUME ["$INSTALL_PATH/public"]

# The default command that gets run
CMD bundle exec rails server -p $PORT -e $RACK_ENV