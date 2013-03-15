require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe User do
  it "should create a new instance given valid attributes" do
    User.create!(
      :name => "username",
      :email    => "user@example.com",
      :password => "password",
      :phone => "+18587614144"
    )
  end
end
