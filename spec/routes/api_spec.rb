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
    @user ||= FactoryGirl.create(:user)

    10.times do
      @user.conversations.create
    end

    @user.conversations.each do |conversation|
      25.times do
        video = conversation.videos.create(user: @user, :filename => "hello.mp4")
        video.in_progress = false
        video.save
      end
    end

    @second_user ||= FactoryGirl.create(:user)
    @conversation = @user.conversations.last
    @access_token = @user.devices.first.access_token 
    @second_token = @second_user.devices.first.access_token 
  end

  before(:each) do
    VideoStitchRequest.jobs.clear
  end

  let(:subject) { @user }
  let(:secondary_subject) { @second_user }
  let(:conversation) { @conversation }
  let(:access_token) { @access_token }
  let(:second_token) { @second_token }

  it 'shows an index' do
    get ''
    last_response.should be_ok
  end

  it 'POST verify | should return access_token' do
    post '/verify', phone: subject.phone_normalized, code: subject.verification_code,
      :platform => "android", :device_token => "hello"
    result = JSON.parse(last_response.body)
    last_response.should be_ok
    result['access_token'].should_not be_nil
    result['user']['access_token'].should_not be_nil
  end

  it 'POST verify | should fail: requires params' do
    post '/verify'

    result = JSON.parse(last_response.body)
    last_response.should_not be_ok
    result['meta']['msg'].should_not be_blank
    result['meta']['errors'].is_a?(Array).should be_true
  end

  it 'POST register | should fail: requires params' do
    post '/register'

    result = JSON.parse(last_response.body)
    last_response.should_not be_ok
    result['meta']['msg'].should_not be_blank
    result['meta']['errors'].is_a?(Array).should be_true
  end

  it 'POST register | creates a user' do
    post '/register', :username => "myname", :phone => "8587614144"

    result = JSON.parse(last_response.body)
    last_response.should be_ok
  end

  it 'POST session | should respond with success phone number' do
    device_count = subject.devices.count
    post '/session', :phone => subject.phone_normalized

    result = JSON.parse(last_response.body)
    last_response.should be_ok
  end

  it 'POST session | should allow signin with email and password' do
    device_count = subject.devices.count
    post '/session', :email => subject.email, :password => "HELLO"

    result = JSON.parse(last_response.body)
    last_response.should be_ok
  end

  it 'DELETE session | deletes the device' do
    user = FactoryGirl.create(:user)
    device_count = user.devices.count

    delete '/session', :access_token => user.devices.first.access_token
    last_response.should be_ok

    user.devices.count.should == device_count - 1
  end

  it 'GET contacts/check | return users from an array or phonenumbers' do
    get '/contacts/check', :numbers => [[secondary_subject.phone_normalized]]

    result = JSON.parse(last_response.body)

    secondary_subject.username.should == result['data'][0]["username"]

    last_response.should be_ok
  end

  it 'GET contacts/check | return contacts' do
    get '/contacts/check', :c => [{"n" => secondary_subject.name, "p" => secondary_subject.phone_hashed}]

    result = JSON.parse(last_response.body)

    secondary_subject.username.should == result['data'][0]["username"]

    last_response.should be_ok
  end

  it 'GET contacts/check | return contacts with access_token' do
    get '/contacts/check', :access_token => access_token, :c => [{"n" => secondary_subject.name, "p" => secondary_subject.phone_hashed}]

    result = JSON.parse(last_response.body)

    secondary_subject.name.should == result['data'][0]["name"]

    last_response.should be_ok
  end

  it 'GET me | error message when not authenticated' do
    get '/me'
    last_response.should_not be_ok
  end

  it 'POST me | updates the user' do
    post '/me', :access_token => access_token, :username => "jeff"
    last_response.should be_ok

    result = JSON.parse(last_response.body)

    subject.reload.username.should == result['data']['username']
  end


  it 'GET me/conversations | gets users conversations' do
    get '/me/conversations', :access_token => access_token

    result = JSON.parse(last_response.body)
    conversations = result['data']['conversations']

    last_response.should be_ok
    conversations.should be_a_kind_of(Array)
  end

  it 'GET me/conversations | should paginate' do
    limit = 1

    get '/me/conversations', :access_token => access_token, :page => 1, :perPage => limit

    result = JSON.parse(last_response.body)
    conversations = result['data']['conversations']

    last_response.should be_ok
    conversations.count.should ==  limit
  end

  it 'GET me/conversations | updated_at' do
    get '/me/conversations', :access_token => access_token, :updated_at => Time.now

    result = JSON.parse(last_response.body)
    conversations = result['data']['conversations']

    last_response.should be_ok
    conversations.count.should == 0
  end

  it 'POST me/conversations | create a conversation' do
    conversations_count = subject.conversations.count
    post '/me/conversations', :access_token => access_token, "invites[]" => [secondary_subject.phone_normalized,"+18888888888"]

    result = JSON.parse(last_response.body)

    last_response.should be_ok
    subject.conversations.reload.count.should == conversations_count + 1
    subject.conversations.find(result["data"]["id"]).invites.count.should == 1
  end

  it 'POST me/conversations | create a conversation with a title' do
    name = "this should be a title"
    conversations_count = subject.conversations.count
    post '/me/conversations',
      :access_token => access_token,
      "invites[]" => [secondary_subject.phone_normalized,"+18887777777"],
      :name => name

    result = JSON.parse(last_response.body)

    last_response.should be_ok
    subject.conversations.reload.find_by_name(name).should_not be_nil
  end

  it 'POST me/conversations | return error if no invites sent' do
    conversations_count = subject.conversations.count
    post '/me/conversations', :access_token => access_token

    result = JSON.parse(last_response.body)

    last_response.should_not be_ok
    result['meta']['code'].should == 400
    result['meta']['msg'].should == "missing invites param"
    subject.conversations.reload.count.should == conversations_count
  end

  it 'POST me/conversations/batch | should create multiple conversations' do
    parts = [
      "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.0.mp4",
      "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.1.mp4",
      "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.2.mp4",
      "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.3.mp4",
      "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.4.mp4",
      "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.5.mp4",
      "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.6.mp4"
    ]

    conversations_count = subject.conversations.count
    post '/me/conversations/batch', :access_token => access_token,
      "invites[]" => [secondary_subject.phone_normalized, "+18888888888"],
      :parts => parts

    result = JSON.parse(last_response.body)
    result['data'].count.should == 2

    last_response.should be_ok
    subject.conversations.reload.count.should == conversations_count + 2
  end


  it 'GET me/conversations/:id | get a specific conversation' do
    get "/me/conversations/#{conversation.id}", :access_token => access_token

    result = JSON.parse(last_response.body)
    last_response.should be_ok
    result['data']['name'].should == subject.conversations.find(conversation.id).name(subject)
  end

  it 'POST me/conversations/:id/videos/parts | sends a video' do
    parts = [
      "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.0.mp4",
      "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.1.mp4",
      "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.2.mp4",
      "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.3.mp4",
      "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.4.mp4",
      "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.5.mp4",
      "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.6.mp4"
    ]

    post "/me/conversations/#{secondary_subject.conversations.first.id}/videos/parts",
      access_token: second_token,
      parts: parts

    last_response.should be_ok
    VideoStitchRequest.jobs.size.should == 1
  end

  it 'POST me/conversations/:id/videos/parts | requires parts param' do
    post "/me/conversations/#{secondary_subject.conversations.first.id}/videos/parts", access_token: second_token

    result = JSON.parse(last_response.body)
    last_response.should_not be_ok
    result['meta']['code'].should == 400
    result['meta']['msg'].should == "missing parts param"
    VideoStitchRequest.jobs.size.should == 0
  end

  it 'POST me/conversations/:id/videos | sends a video' do
    c = secondary_subject.conversations.reload.first

    post "/me/conversations/#{c.id}/videos", access_token: second_token, filename: 'video1.mp4'

    last_response.should be_ok
    c.reload.videos.first.filename.should == "video1.mp4"
  end

  it 'POST me/conversations/:id/videos | requires filename param' do
    c = secondary_subject.conversations.reload.first

    post "/me/conversations/#{c.id}/videos", access_token: second_token

    result = JSON.parse(last_response.body)
    last_response.should_not be_ok
    result['meta']['code'].should == 400
    result['meta']['msg'].should == "missing filename param"
  end

  it "GET me/conversations/:id/videos | should get all videos" do
    #expect{subject.conversations.find(conversation.id)}.to_not raise_error(::ActiveRecord::RecordNotFound)

    get "/me/conversations/#{conversation.id}/videos", :access_token => access_token

    videos_count = conversation.videos_for(subject).reload.count

    result = JSON.parse(last_response.body)
    last_response.should be_ok

    result["data"].count.should == videos_count
  end

  it "GET me/conversations/:id/videos | should paginate and default to 10" do
    get "/me/conversations/#{conversation.id}/videos", :access_token => access_token, :page => 1

    result = JSON.parse(last_response.body)
    last_response.should be_ok

    result["data"].count.should == 10
    result["meta"]["last_page"].should be_false
  end

  it 'POST me/conversations/:id/leave | leave a group' do
    expect{subject.conversations.find(conversation.id)}.to_not raise_error(::ActiveRecord::RecordNotFound)
    post "/me/conversations/#{conversation.id}/leave", access_token: access_token

    expect{subject.conversations.reload.find(conversation.id)}.to raise_error(::ActiveRecord::RecordNotFound)
  end

  it 'POST me/videos/:id/read | user reads a video' do
    conversation = subject.conversations.reload.first
    video = conversation.videos.first
    video.unread?(subject).should be_true

    post "/me/videos/#{video.id}/read", access_token: access_token
    last_response.should be_ok
    video.reload.unread?(subject).should be_false
  end
end
