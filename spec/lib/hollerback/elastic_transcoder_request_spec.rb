require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Hollerback::ElasticTranscoderRequest do
  before(:all) do
    @video = FactoryGirl.create(:video)
    @video.filename = "_testSegmentedVids/4D/E937D335-7CFD-438F-91F7-C37FDE8EEA6B.0.mp4"
  end

  let(:video) { @video }

  it "should create a job" do
    jobs_count = StreamJob.all.count
    job = Hollerback::ElasticTranscoderRequest.new(video)
    job.run
    StreamJob.all.count.should == jobs_count + 1
  end

  it "StreamJob should set status when complete!" do
    s = StreamJob.first
    s.complete!
    s.video.streamname.should_not be_blank
  end
end
