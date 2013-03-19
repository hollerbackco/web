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
        if user = User.find_by_phone_normalized(phone)
          conversation.members << user
        else
          Invite.create(
            phone: phone,
            inviter: inviter,
            conversation: conversation
          )
          Hollerback::SMS.send_message phone, "#{inviter.name} has invited you to Hollerback"
        end
      end
    end

    private

    def parsed_phones
      phones.map do |phone|
        Phoner::Phone.parse(phone, country_code: inviter.phone_country_code, area_code: inviter.phone_area_code).to_s
      end.compact
    end

  end
end
