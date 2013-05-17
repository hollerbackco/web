Honeybadger.configure do |config|
  config.api_key = ENV['HONEYBADGER_API_KEY']
end

if Sinatra::Base.production? or Sinatra::Base.settings == :staging
  use Honeybadger::Rack
end
