ENV['RACK_ENV'] = "test"
ENV['DATABASE_URL'] = "postgres:///hollerback_test"

require File.join(File.dirname(__FILE__), "..", "config", "environment.rb")
Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f}

#utils
require 'rack/test'
require 'database_cleaner'
require 'sms_spec'
require 'em-rspec'
require 'sidekiq/testing'
require 'factory_girl'
require 'ffaker'

set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include Warden::Test::Helpers
  config.include SmsSpec::Helpers
  config.include SmsSpec::Matchers

  config.after(:each) do
    Warden.test_reset!
  end

  config.before(:suite) do
    ActiveRecord::Migrator.migrate(
      'db/migrate', nil
    )
    ActiveRecord::Base.logger = nil

    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)

    FactoryGirl.find_definitions
  end
end

