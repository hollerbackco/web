module Hollerback
  class ContactChecker
    attr_accessor :phones, :inviter

    def initialize(numbers, user)
      self.phones = numbers || []
      self.inviter = user
    end

    def contacts
      parsed_phones.map do |phone|
        User.where(phone_normalized: phone)
      end.flatten.uniq - [self.inviter]
    end

    def parsed_phones
      self.phones.map do |phone|
        Phoner::Phone.parse(phone, country_code: inviter.phone_country_code, area_code: inviter.phone_area_code).to_s
      end.compact
    end
  end
end
