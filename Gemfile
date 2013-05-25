ruby "2.0.0"
source 'http://rubygems.org'
source 'http://gemcutter.org'

gem 'rake'

#server
gem 'thin'
gem 'sinatra', :require => "sinatra/base"
gem 'sinatra-contrib'

#database
gem 'activerecord'
gem 'sinatra-activerecord'
gem 'pg'
gem 'redis'

#model
gem 'unread'
gem 'awesome_nested_set'

#views
gem 'haml'

#authentication
gem 'warden'
gem 'omniauth'
gem 'omniauth-twitter'

#storage
gem 'aws-sdk'

#messaging
gem 'phone'
gem 'twilio-ruby'

#utils
gem 'split', :require => 'split/dashboard'
gem 'split-analytics', :require => 'split/analytics'
gem 'apns'
gem 'gcm'
gem 'bcrypt-ruby'
gem 'time-lord'
gem 'i18n'
gem "em-http-request", "~> 1.0"

#background
gem 'slim'
gem 'sidekiq'
gem 'streamio-ffmpeg'
gem 'mini_magick'

#analytics
gem 'keen'
gem 'newrelic_rpm'

gem 'keen'
gem 'newrelic_rpm'
gem 'honeybadger'

#assets
gem 'sprockets'
gem 'sprockets-helpers'
gem 'sprockets-sass'
gem 'coffee-script'
gem 'compass'
gem 'handlebars_assets'

group :development do
  gem 'rerun'
  gem 'rb-fsevent'
  gem 'tux'
  gem 'guard-sprockets2'
  gem 'yui-compressor'
  gem 'uglifier'
  gem 'reek'
  gem 'flay'
end

group :test do
  gem 'rspec'
  gem 'sqlite3'
  gem 'database_cleaner'
  gem 'sms-spec'
  gem 'factory_girl'
  gem 'ffaker'
end

group :test, :development do
  gem 'guard-rspec'
  gem 'em-rspec'
end
