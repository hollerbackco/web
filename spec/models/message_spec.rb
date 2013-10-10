require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Message do
  before(:all) do
    conversation = FactoryGirl.create(:conversation)
    conversation.members << FactoryGirl.create(:user)
    @membership = conversation.memberships.first
    @message = Message.create(membership: @membership, video_guid: SecureRandom.uuid)
  end

  let(:message) { @message }

  it "should update seen_at when seen! is called" do
    message.seen_at.should be_nil
    message.seen!
    message.seen_at.class.should == Time
  end
end
