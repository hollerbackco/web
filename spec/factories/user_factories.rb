FactoryGirl.define do
  factory :user do
    email               { Faker::Internet.email }
    name                { Faker::Name.name }
    username            { Faker::Name.name }
    phone               { Faker::PhoneNumber.phone_number }
    password            { "HELLO" }
  end
end
