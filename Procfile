web: thin start -p $PORT
worker: bundle exec sidekiq -c 15 -r ./config/environment.rb
