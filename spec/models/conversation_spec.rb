require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Conversation do
  before(:all) do
    @conversation = FactoryGirl.create(:conversation)
    @second_user = FactoryGirl.create(:user)
    @conversation.members << @second_user
  end

  let(:conversation) { @conversation }
  let(:user) { @conversation.creator }
  let(:second_user) { @second_user }
end
