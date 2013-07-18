require File.expand_path('./config/environment')
require 'sidekiq/web'

use Rack::MethodOverride
use Rack::Session::Cookie, :secret => 'change_me_again'

use Rack::ReverseProxy do 
  # Set :preserve_host to true globally (default is true already)
  reverse_proxy_options :preserve_host => false

  #Forward the path /test* to http://example.com/test*
  reverse_proxy '/blog', 'http://ec2-72-44-44-118.compute-1.amazonaws.com/blog'
end

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
