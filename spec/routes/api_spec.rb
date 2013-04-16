require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe 'API ROUTES |' do
  include Rack::Test::Methods

  def app
    Rack::Builder.new do
      Warden::Manager.serialize_into_session { |user| user.id }
      Warden::Manager.serialize_from_session { |id| User.find(id) }
      HollerbackApp::ApiApp

      use Rack::Session::Cookie, :secret => "change_me_again"
      use Warden::Manager do |config|
        config.failure_app = HollerbackApp::ApiApp

        config.scope_defaults :default,
          strategies: [:password, :api_token],
          action: '/unauthenticated'
      end

      run HollerbackApp::ApiApp
    end
  end

  before(:all) do
    @user ||= User.create!(
      name: "test user",
      email: "test@test.com",
      password: "testtest",
      phone: "+18886664444"
    )
  end

  let(:subject) { @user }
  let(:access_token) { @user.access_token }

  it 'shows an index' do
    get ''
    last_response.should be_ok
  end

  it 'POST session | responds with an access_token' do
    post '/session', :email => "test@test.com", :password => "testtest"

    result = JSON.parse(last_response.body)
    last_response.should be_ok
    result['access_token'].should == subject.access_token
  end

  it 'POST session | returns 403 when incorrect password' do
    post '/session', :email => "test@test.com", :password => "test"
    last_response.should_not be_ok
  end

  it 'GET /me | error message when not authenticated' do
    get '/me'
    last_response.should_not be_ok
  end

  it 'POST me | updates the user' do
    post '/me', :access_token => access_token, :name => "jeff"
    last_response.should be_ok

    result = JSON.parse(last_response.body)

    subject.name.should_not == result['data']['name']
    #because its not reloaded yet
    subject.reload.name.should == result['data']['name']
  end


  it 'GET me/conversations | gets users conversations' do
    post '/me/conversations', :access_token => access_token
    result = JSON.parse(last_response.body)

    conversations == result['data']['conversations']

    last_response.should be_ok
    conversations.should be_a_kind_of(Array)
  end
end
