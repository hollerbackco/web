require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe User do
  before(:all) do
    @user ||= FactoryGirl.create(:user)
  end

  let(:user) { @user }

  it "should have a device" do
    user.devices.count.should == 1
  end

  it "should generate a verification thats 6 characters in length" do
    user.verification_code.should_not be_nil
    user.verification_code.length.should == 6
  end

  it "should not be verified before verifying" do
    user.verified?.should be_false
  end

  it "should verify with the corrent code" do
    user.verify!(user.verification_code)
    user.verified?.should be_true
  end

  it "should return an isVerified attribute in json object" do
    user.as_json.key?(:isVerified).should be_true
  end

  it "should create a device when token is set" do
    device_count = user.devices.count
    user.device_token = "helo"
    user.save
    user.devices.reload.count.should == device_count + 1
  end
end
