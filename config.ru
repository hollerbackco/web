require File.expand_path('./config/environment')
require 'sidekiq/web'

disable :run

use Rack::MethodOverride
use Rack::Session::Cookie, :secret => 'change_me_again'

map '/api' do
  run HollerbackApp::ApiApp
end

map '/split' do
  run ::Split::Dashboard
end

map '/sidekiq' do
  run ::Sidekiq::Web
end

Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    username == 'jnoh' && password == 'watchthis'
end 

map HollerbackApp::WebApp.settings.assets_prefix do
  run HollerbackApp::WebApp.sprockets
end

map '/' do
  run HollerbackApp::WebApp
end
