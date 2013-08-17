module Hollerback
  class ConversationInviter
    attr_accessor :inviter, :conversation, :phones

    def initialize(user,convo,numbers)
      self.inviter = user
      self.conversation = convo
      self.phones = numbers
    end

    def invite
      parsed_phones.each do |phone|
        if users = User.where(phone_normalized: phone) and users.any?
          conversation.members << users.first
        else
          Invite.create(
            phone: phone.first,
            inviter: inviter,
            conversation: conversation
          )

          #TODO: send a text message to non users
          #Hollerback::SMS.send_message phone, "#{inviter.name} has invited you to Hollerback"
        end
      end
    end

    def parsed_phones
      self.phones.map do |phone|
        Phoner::Phone.parse(phone, country_code: inviter.phone_country_code, area_code: inviter.phone_area_code).to_s
      end.compact
    end

    def self.parse(user, numbers)
      numbers.map do |phone|
        Phoner::Phone.parse(phone, country_code: user.phone_country_code, area_code: user.phone_area_code).to_s
      end.compact
    end
  end
end
