require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Membership do
  before(:all) do
    conversation = FactoryGirl.create(:conversation)
    conversation.members << conversation.creator
    conversation.members << FactoryGirl.create(:user)
    @membership = Membership.first
    Message.create(membership: @membership)
  end

  let(:membership) { @membership }

  it "json should include members" do
    json = membership.as_json
    json.key?(:members).should be_true
  end

  it "json should have an updated_at equal to last_message_at" do
    json = membership.as_json
    membership.messages.should_not be_empty
    json.key?(:updated_at).should be_true
    json[:updated_at].should == membership.last_message_at
  end
end
