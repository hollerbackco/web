require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe User do

  before(:all) do
    @user ||= User.create(
      :name => "test2",
      :username => "test2",
      :email    => "test2@example.com",
      :password => "password",
      :phone => "+18588886666"
    )
  end

  let(:user) { @user }

  it "should create a new instance given valid attributes" do
    User.create!(
      :name => "username",
      :username => "username",
      :email    => "user@example.com",
      :password => "password",
      :phone => "+18587614144"
    )
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
end
