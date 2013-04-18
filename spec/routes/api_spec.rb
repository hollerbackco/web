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

    @conversation = @user.conversations.create

    @second_user ||= User.create!(
      name: "second user",
      email: "second@test.com",
      password: "secondtest",
      phone: "+18886668888"
    )
  end

  let(:subject) { @user }
  let(:secondary_subject) { @second_user }
  let(:conversation) { @conversation }
  let(:access_token) { @user.access_token }
  let(:second_token) { @second_user.access_token }

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
    get '/me/conversations', :access_token => access_token

    result = JSON.parse(last_response.body)
    conversations = result['data']['conversations']

    last_response.should be_ok
    conversations.should be_a_kind_of(Array)
  end

  it 'POST me/conversations | create a conversation' do
    post '/me/conversations', :access_token => access_token, "invites[]" => "+18886668888"

    result = JSON.parse(last_response.body)

    last_response.should be_ok
    subject.conversations.reload.count.should == 2
  end

  it 'GET me/conversations/:id | get a specific conversation' do
    get "/me/conversations/#{conversation.id}", :access_token => access_token

    result = JSON.parse(last_response.body)
    last_response.should be_ok
    result['data']['name'].should == subject.conversations.find(1).name(subject)
  end

  it 'post me/conversations/:id/leave | leave a group' do
    expect{subject.conversations.find(1)}.to_not raise_error(::ActiveRecord::RecordNotFound)
    post '/me/conversations/1/leave', access_token: access_token

    expect{subject.conversations.reload.find(1)}.to raise_error(::ActiveRecord::RecordNotFound)
  end

  it 'post me/conversations/:id/videos | sends a video' do
    post '/me/conversations/2/videos', access_token: second_token, filename: 'video1.mp4'

    last_response.should be_ok
    secondary_subject.conversations.find(2).videos.first.filename.should == "video1.mp4"
  end

  it 'post me/videos/:id/read | user reads a video' do
    video = subject.conversations.find(2).videos.first
    video.unread?(subject).should be_true

    post "/me/videos/#{video.id}/read", access_token: access_token
    last_response.should be_ok
    video.reload.unread?(subject).should be_false
  end
end
