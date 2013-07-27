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
    contact_book.update([
      {
        "name" => "test",
        "phone" => "hashedphonenumberhere"
      },
      {
        "name" => user.username,
        "phone" => user.phone_hashed
      }
    ])

    contact_book.contacts.reload.count.should == 2
  end

  it "should return hollerback users" do
    contact_book.contacts_on_hollerback.count.should == 1
  end
end
