ENV['RACK_ENV'] = "test"
ENV['DATABASE_URL'] = "postgres:///hollerback_test"

require File.join(File.dirname(__FILE__), "..", "config", "environment.rb")

#utils
require 'rack/test'
require 'database_cleaner'
require 'sms_spec'

set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include SmsSpec::Helpers
  config.include SmsSpec::Matchers

  config.before(:suite) do
    ActiveRecord::Migrator.migrate(
      'db/migrate', nil
    )

    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end
end

