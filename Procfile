web: bundle exec unicorn -p $PORT -c ./config/unicorn.rb
worker: bundle exec sidekiq -c 15 -r ./config/environment.rb
sqs_worker: bundle exec ./bin/video_ready_poller_service.rb
