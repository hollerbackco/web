module PhoneFake
  def self.phone_number
    rand(10 ** 10).to_s.rjust(10,'0')
  end
end

FactoryGirl.define do
  factory :user do
    username            { Faker::Name.name.gsub(" ", "_").downcase }
    phone               { PhoneFake.phone_number }

    after(:create) do |user|
      user.devices << Device.create(platform: "ios", token: "devicetoken#{Faker::Name.name}")
    end
  end
end
