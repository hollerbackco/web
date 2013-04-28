require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class CoreHelpersTest
  include Sinatra::CoreHelpers

  def initialize(user)
    @user = user
  end

  def current_user
    @user
  end
end

describe 'Core helpers' do

  before do
    @user ||= User.create!(
      name: "helpers",
      username: "helpers",
      email: "helpers@test.com",
      password: "helpers",
      phone: "+18886669999"
    )

    @conversation = @user.conversations.create
  end

  after(:all) do
    DatabaseCleaner.clean_with(:truncation)
  end

  let(:subject) { CoreHelpersTest.new(@user) }
  let(:user) { @user }
  let(:conversation) { @conversation }

  it "creates the correct json object" do
    obj = subject.conversation_json(@conversation)

    obj["name"].should == "(0) Invited"
  end
end
