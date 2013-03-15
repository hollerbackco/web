require File.expand_path('./config/environment')

disable :run

use Rack::MethodOverride
use Rack::Session::Cookie, :secret => 'change_me'

use Warden::Manager do |config|
  config.scope_defaults :default,
    strategies: [:password, :api_token],
    action: 'session/unauthenticated'
  config.failure_app = self
end

map '/session' do
  run HollerbackApp::Session
end

map '/register' do
  run HollerbackApp::Register
end

map '/' do
  run HollerbackApp::Main
end
