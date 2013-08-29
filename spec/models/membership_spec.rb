require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Membership do
  before(:all) do
    conversation = FactoryGirl.create(:conversation)
    conversation.members << conversation.creator
    conversation.members << FactoryGirl.create(:user)
    @membership = Membership.first
  end

  let(:membership) { @membership }

  it "membership as_json" do
    json = membership.as_json
    json.key?(:members).should be_true
  end
end
