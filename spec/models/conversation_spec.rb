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

  it "should include all sent videos in the list even when in_progess" do
    video = conversation.videos.create(
      user: user,
      filename: "hello.mp4"
    )
    video.in_progress.should be_true
    conversation.videos_for(user).include?(video).should be_true
  end

  it "should not see videos in_progress if sent by another user" do
    video = conversation.videos.create(
      user: user,
      filename: "hello.mp4"
    )
    video.in_progress.should be_true
    conversation.videos_for(second_user).include?(video).should_not be_true
  end
end
