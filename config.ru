require File.expand_path('./config/environment')

disable :run

use Rack::MethodOverride
use Rack::Session::Cookie, :secret => 'change_me_again'

use Warden::Manager do |config|
  config.failure_app = HollerbackApp::ApiApp

  config.scope_defaults :default,
    strategies: [:password, :api_token],
    action: '/unauthenticated'
end

map '/api' do
  run HollerbackApp::ApiApp
end

map '/split' do
  run ::Split::Dashboard
end

map HollerbackApp::WebApp.settings.assets_prefix do
  run HollerbackApp::WebApp.sprockets
end

map '/' do
  run HollerbackApp::WebApp
end
