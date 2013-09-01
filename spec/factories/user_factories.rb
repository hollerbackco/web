FactoryGirl.define do
  factory :user do
    username            { Faker::Name.name.gsub(" ", "_").downcase }
    phone               { Faker::PhoneNumber.phone_number }

    after(:create) do |user|
      user.devices << Device.create(platform: "ios", token: "devicetoken#{Faker::Name.name}")
    end
  end
end
