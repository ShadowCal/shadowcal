release: bundle exec rake db:migrate
web: bundle exec rails server -p $PORT -e $RACK_ENV
worker: bundle exec rake jobs:work
