require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Hollerback::ContactBook do
  before(:all) do
    @user ||= FactoryGirl.create(:user)
  end

  let(:user) { @user }
  let(:contact_book) { Hollerback::ContactBook.new(user)}

  it "should have an empty contact book" do
    contact_book.contacts.should be_empty
  end

  it "should update contacts" do
    contact_book.update([{
      "name" => "Jeffrey Noh",
      "phone" => "hashedphonenumberhere"
    }])

    contact_book.contacts.reload.count.should == 1
  end
end
