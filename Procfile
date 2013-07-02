web: thin start -p $PORT
worker: bundle exec sidekiq -c 15 -r ./config/environment.rb
sqs_worker: bundle exec ./app/jobs/video_complete_poller.rb
