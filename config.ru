require 'sinatra'
require 'warden'
require File.expand_path('./config/environment')
require File.join(File.dirname(__FILE__), 'app/app')
require File.join(File.dirname(__FILE__), 'app/session')

disable :run

Warden::Manager.serialize_into_session{|user| user.id }
Warden::Manager.serialize_from_session{|id| User[id] }

Warden::Manager.before_failure do |env,opts|
  env['REQUEST_METHOD'] = 'POST'
end

Warden::Strategies.add(:password) do
  def valid?
    params['user'] && params['user']['name'] && params['user']['password']
  end

  def authenticate!
    user = User.authenticate(
      params['user']['name'],
      params['user']['password']
      )
    user.nil? ? fail!('Could not log in') : success!(user, 'Successfully logged in')
  end
end

Warden::Strategies.add :api_token
  def authenticate!
    if token = params[:api_token]
      user = User.authenticate_with_api_token(token.strip)
      user.nil? ? fail!('No api key') : success!(user)
    end
  end
end

use Rack::MethodOverride
use Rack::Session::Cookie

use Warden::Manager do |config|
  config.scope_defaults :default,
    strategies: [:password, :api_token],
    action: 'session/unauthenticated'
  config.failure_app = self
end

map '/session' do
  run HollerbackApp::Session
end

map '/' do
  run HollerbackApp::Main
end
