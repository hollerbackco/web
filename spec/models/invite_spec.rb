require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Invite do
  before(:all) do
    @user = FactoryGirl.create(:user)
    @conversation = FactoryGirl.create(:conversation)
    @invite = @conversation.invites.create(
      phone: @user.phone
    )
  end

  let(:user) { @user }

  it "a new invite should start off as not accepted" do
    @invite.accepted?.should be_false
  end

  it "requires a phone" do
    invite = Invite.create
    invite.errors.any?.should be_true
  end

  it "when accepted and join a user to a group" do
    @conversation.members.should_not include(@user)

    @invite.accept!(@user)

    @conversation.members.reload.should include(@user)
    @invite.accepted?.should be_true
  end
end
