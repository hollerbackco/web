require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe VideoStitchAndSend do
  let(:video) { @user ||= FactoryGirl.create(:video) }

  it "should run without specifying a filename" do
    TEST_VIDEOS = [
      "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.0.mp4",
      "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.1.mp4",
      "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.2.mp4",
      "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.3.mp4",
      "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.4.mp4",
      "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.5.mp4",
      "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.6.mp4"
    ]

    job = VideoStitchAndSend.new
    job.perform(TEST_VIDEOS, video.id)
  end

  it "should run with specifying a filename" do
    TEST_VIDEOS = [
      "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.0.mp4",
      "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.1.mp4",
      "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.2.mp4",
      "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.3.mp4",
      "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.4.mp4",
      "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.5.mp4",
      "_testSegmentedVids/4A/6A2B3BFD-AD55-4D6A-9AC1-A79321CC24C5.6.mp4"
    ]

    job = VideoStitchAndSend.new
    job.perform(TEST_VIDEOS, video.id, "test/hello.mp4")
    video.reload.filename.should == "test/hello.mp4"
  end
end
