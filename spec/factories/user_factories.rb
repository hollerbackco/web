FactoryGirl.define do
  factory :user do
    email               { Faker::Internet.email }
    name                { Faker::Name.name }
    username            { Faker::Name.name }
    phone               { Faker::PhoneNumber.phone_number }
    #password            { "HELLO" }

    after(:create) do |user|
      user.devices << Device.create(platform: "ios", token: "devicetoken#{Faker::Name.name}")
    end
  end
end
