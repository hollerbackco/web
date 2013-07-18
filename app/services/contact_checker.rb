module Hollerback
  class ContactChecker
    attr_accessor :phones, :inviter

    def initialize(numbers, user=nil)
      self.phones = numbers || []
      self.inviter = user
    end

    def contacts
      users = User.all(conditions: [ "phone_normalized IN (:phone_normalized)", {phone_normalized: phones}]).flatten.uniq
      if self.inviter.present?
        users = users - [self.inviter]
      end
      users
    end

    def parsed_phones
      self.phones.map do |phone|
        Phoner::Phone.parse(phone, country_code: inviter.phone_country_code, area_code: inviter.phone_area_code).to_s
      end.compact
    end
  end
end
