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
    DatabaseCleaner.clean!
    @user ||= FactoryGirl.create(:user)

    3.times do
      @user.conversations.create
    end

    @user.conversations.each do |conversation|
      membership = Membership.where(user_id: @user.id, conversation_id: conversation.id).first
      10.times do
        publisher = ContentPublisher.new(membership)
        video = conversation.videos.create(user: @user, :filename => "hello.mp4", in_progress: false)
        publisher.publish(video, notify: false, analytics: false)
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
    get '/contacts/check', :c => [{"n" => secondary_subject.username, "p" => secondary_subject.phone_hashed}]

    result = JSON.parse(last_response.body)

    secondary_subject.username.should == result['data'][0]["username"]

    last_response.should be_ok
  end

  it 'GET contacts/check | return contacts with access_token' do
    get '/contacts/check', :access_token => access_token, :c => [{"n" => secondary_subject.username, "p" => secondary_subject.phone_hashed}]

    result = JSON.parse(last_response.body)

    secondary_subject.username.should == result['data'][0]["username"]

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

  it 'GET me/sync | gets a list of syncable objects' do
    get '/me/sync', :access_token => access_token
    last_response.should be_ok

    result = JSON.parse(last_response.body)
    count = subject.reload.memberships.count + subject.messages.limit(100).count
    count.should == result['data'].count
  end

  it 'GET me/sync | only get latest sync objects' do
    membership = subject.memberships.first
    publisher = ContentPublisher.new(membership)
    video = conversation.videos.create(user: subject, :filename => "hello.mp4", in_progress: false)
    publisher.publish(video, notify: false, analytics: false)

    get '/me/sync', :access_token => access_token, :updated_at => Time.now
    last_response.should be_ok

    result = JSON.parse(last_response.body)
    result['data'].count.should == 2
  end

  it 'GET me/conversations | gets users conversations' do
    get '/me/conversations', :access_token => access_token

    result = JSON.parse(last_response.body)
    conversations = result['data']['conversations']

    last_response.should be_ok
    conversations.should be_a_kind_of(Array)
  end

  it 'POST me/conversations | create a conversation' do
    count = subject.memberships.count
    post '/me/conversations', :access_token => access_token, "invites[]" => [secondary_subject.phone_normalized,"+18888888888"]

    result = JSON.parse(last_response.body)

    last_response.should be_ok
    subject.memberships.reload.count.should == count + 1
    subject.memberships.find(result["data"]["id"]).invites.count.should == 1
  end

  it 'POST me/conversations | create a conversation with a title' do
    name = "this should be a title"
    count = subject.memberships.count
    post '/me/conversations',
      :access_token => access_token,
      "invites[]" => [secondary_subject.phone_normalized,"+18887777777"],
      :name => name

    result = JSON.parse(last_response.body)

    last_response.should be_ok
    subject.memberships.reload.find_by_name(name).should_not be_nil
  end

  it 'POST me/conversations | return error if no invites sent' do
    count = subject.memberships.count
    post '/me/conversations', :access_token => access_token

    result = JSON.parse(last_response.body)

    last_response.should_not be_ok
    result['meta']['code'].should == 400
    result['meta']['msg'].should == "missing invites param"
    subject.memberships.reload.count.should == count
  end

  it 'POST me/conversations/:id/watch_all | clear all video notifications' do
    c = secondary_subject.memberships.reload.first
    post "/me/conversations/#{c.id}/watch_all", access_token: second_token

    last_response.should be_ok
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
    c = subject.memberships.first
    get "/me/conversations/#{c.id}", :access_token => access_token

    result = JSON.parse(last_response.body)
    last_response.should be_ok
    result['data']['name'].should == subject.memberships.find(c.id).name
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

    post "/me/conversations/#{secondary_subject.memberships.first.id}/videos/parts",
      access_token: second_token,
      parts: parts

    last_response.should be_ok
    VideoStitchRequest.jobs.size.should == 1
  end

  it 'POST me/conversations/:id/videos/parts | requires parts param' do
    post "/me/conversations/#{secondary_subject.memberships.first.id}/videos/parts", access_token: second_token

    result = JSON.parse(last_response.body)
    last_response.should_not be_ok
    result['meta']['code'].should == 400
    result['meta']['msg'].should == "missing parts param"
    VideoStitchRequest.jobs.size.should == 0
  end

  it 'POST me/conversations/:id/videos | sends a video' do
    c = secondary_subject.memberships.reload.first

    post "/me/conversations/#{c.id}/videos", access_token: second_token, filename: 'video1.mp4'

    last_response.should be_ok
    c.reload.messages.should_not be_empty
  end

  it 'POST me/conversations/:id/videos | requires filename param' do
    c = secondary_subject.memberships.first

    post "/me/conversations/#{c.id}/videos", access_token: second_token

    result = JSON.parse(last_response.body)
    last_response.should_not be_ok
    result['meta']['code'].should == 400
    result['meta']['msg'].should == "missing filename param"
  end

  it "GET me/conversations/:id/videos | should get all videos" do
    c = subject.memberships.last
    get "/me/conversations/#{c.id}/videos", :access_token => access_token

    messages_count = c.messages.count

    result = JSON.parse(last_response.body)
    last_response.should be_ok

    result["data"].count.should == messages_count
  end

  it "GET me/conversations/:id/videos | should paginate" do
    c = subject.memberships.last
    get "/me/conversations/#{c.id}/videos", :access_token => access_token, :page => 1, :perPage => 5

    result = JSON.parse(last_response.body)
    last_response.should be_ok

    result["data"].count.should == 5
    result["meta"]["last_page"].should be_false
  end

  it 'POST me/conversations/:id/leave | leave a group' do
    c = subject.memberships.first
    post "/me/conversations/#{c.id}/leave", access_token: access_token

    expect{subject.memberships.reload.find(c.id)}.to raise_error(::ActiveRecord::RecordNotFound)
  end

  it 'POST me/videos/:id/read | user reads a video' do
    c = secondary_subject.memberships.first
    message = c.messages.first
    message.seen_at = nil
    message.save
    message.unseen?.should be_true

    post "/me/videos/#{message.id}/read", access_token: second_token
    last_response.should be_ok
    message.reload.unseen?.should be_false
  end
end
