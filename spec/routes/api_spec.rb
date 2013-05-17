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
      username: "test",
      email: "test@test.com",
      password: "testtest",
      phone: "+18886664444"
    )

    @conversation = @user.conversations.create

    @second_user ||= User.create!(
      name: "second user",
      username: "second",
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

  it 'POST /register | requires params' do
    post '/register', :email => "test@test.com", :password => "testtest"

    result = JSON.parse(last_response.body)
    last_response.should_not be_ok
    result['meta']['msg'].should_not be_blank
    result['meta']['errors'].is_a?(Array).should be_true
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

  it 'GET /contacts/check | return users from an array or phonenumbers' do
    get '/contacts/check', :access_token => access_token, :numbers => [[secondary_subject.phone_normalized]]

    result = JSON.parse(last_response.body)

    secondary_subject.name.should == result['data'][0]["name"]

    last_response.should be_ok
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

  it 'POST me | verifies code' do
    post '/me/verify', :access_token => access_token, :code => subject.verification_code
    last_response.should be_ok

    subject.reload.verified?.should be_true
  end


  it 'GET me/conversations | gets users conversations' do
    get '/me/conversations', :access_token => access_token

    result = JSON.parse(last_response.body)
    conversations = result['data']['conversations']

    last_response.should be_ok
    conversations.should be_a_kind_of(Array)
  end

  it 'POST me/conversations | create a conversation' do
    post '/me/conversations', :access_token => access_token, "invites[]" => ["+18886668888","+18888888888"]

    result = JSON.parse(last_response.body)

    last_response.should be_ok
    subject.conversations.reload.count.should == 2
    subject.conversations.find(result["data"]["id"]).invites.count.should == 1
  end

  it 'POST me/conversations | return error if no invites sent' do
    post '/me/conversations', :access_token => access_token

    result = JSON.parse(last_response.body)

    last_response.should_not be_ok
    result['meta']['code'].should == 400
    result['meta']['msg'].should == "missing invites param"
    subject.conversations.reload.count.should == 2
  end

  it 'GET me/conversations/:id | get a specific conversation' do
    get "/me/conversations/#{conversation.id}", :access_token => access_token

    result = JSON.parse(last_response.body)
    last_response.should be_ok
    result['data']['name'].should == subject.conversations.find(conversation.id).name(subject)
  end

  it 'post me/conversations/:id/leave | leave a group' do
    expect{subject.conversations.find(conversation.id)}.to_not raise_error(::ActiveRecord::RecordNotFound)
    post "/me/conversations/#{conversation.id}/leave", access_token: access_token

    expect{subject.conversations.reload.find(conversation.id)}.to raise_error(::ActiveRecord::RecordNotFound)
  end

  it 'post me/conversations/:id/videos/parts | sends a video' do
    TEST_VIDEOS_2 = [
      "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.0.mp4",
      "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.1.mp4",
      "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.2.mp4",
      "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.3.mp4",
      "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.4.mp4",
      "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.5.mp4",
      "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.6.mp4"
    ]

    post "/me/conversations/#{secondary_subject.conversations.first.id}/videos/parts", access_token: second_token, parts: TEST_VIDEOS_2
    VideoStitchAndSend.jobs.size.should == 1
    last_response.should be_ok
    VideoStitchAndSend.jobs.clear
  end

  it 'post me/conversations/:id/videos/parts | requires parts param' do
    post "/me/conversations/#{secondary_subject.conversations.first.id}/videos/parts", access_token: second_token

    result = JSON.parse(last_response.body)
    last_response.should_not be_ok
    result['meta']['code'].should == 400
    result['meta']['msg'].should == "missing parts param"
    VideoStitchAndSend.jobs.size.should == 0
  end

  it 'post me/conversations/:id/videos | sends a video' do
    conversation = secondary_subject.conversations.reload.first

    post "/me/conversations/#{conversation.id}/videos", access_token: second_token, filename: 'video1.mp4'

    last_response.should be_ok
    secondary_subject.conversations.find(conversation.id).videos.first.filename.should == "video1.mp4"
  end

  it 'post me/conversations/:id/videos | requires filename param' do
    conversation = secondary_subject.conversations.reload.first

    post "/me/conversations/#{conversation.id}/videos", access_token: second_token

    result = JSON.parse(last_response.body)
    last_response.should_not be_ok
    result['meta']['code'].should == 400
    result['meta']['msg'].should == "missing filename param"
  end

  it 'post me/videos/:id/read | user reads a video' do
    conversation = subject.conversations.reload.first
    video = conversation.videos.first
    video.unread?(subject).should be_true

    post "/me/videos/#{video.id}/read", access_token: access_token
    last_response.should be_ok
    video.reload.unread?(subject).should be_false
  end
end
