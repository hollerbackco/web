
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ContentPublisher do
  before(:all) do
    conversation = FactoryGirl.create(:conversation)
    second_user = FactoryGirl.create(:user)
    conversation.members << second_user
    @membership = Membership.where(:user_id => second_user.id, :conversation_id => conversation.id).first
  end

  subject {ContentPublisher.new(@membership)}

  it "should publish and return messages" do
    video = FactoryGirl.create(:video)
    subject.publish(video)
    p subject.messages.as_json
    subject.messages.should_not be_empty
  end
end
