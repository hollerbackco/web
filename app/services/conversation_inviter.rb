module Hollerback
  class ConversationInviter
    attr_accessor :inviter, :conversation, :phones, :name

    def initialize(user, numbers, name=nil)
      self.inviter = user
      self.phones = numbers
      self.name = name
    end

    def invite
      success = Conversation.transaction do
        self.conversation = create_conversation
        phones.each do |phone|
          if users = User.where(phone_normalized: phone) and users.any?
            user = users.first
            next if conversation.members.exists?(user)
            conversation.members << user
          else
            Invite.create(
              phone: phone,
              inviter: inviter,
              conversation: conversation
            )
          end
        end
        run_analytics
      end
    end

    def parsed_phones
      self.phones.map do |phone|
        Phoner::Phone.parse(phone, country_code: inviter.phone_country_code, area_code: inviter.phone_area_code).to_s
      end.compact.uniq
    end

    def self.parse(user, numbers)
      numbers.map do |phone|
        Phoner::Phone.parse(phone, country_code: user.phone_country_code, area_code: user.phone_area_code).to_s
      end.compact
    end

    def errors
      conversation.errors
    end

    def inviter_membership
      inviter.memberships.find(:first, conditions: {conversation_id: conversation.id})
    end

    private

    def create_conversation
      inviter.conversations.create(creator: inviter, name: name)
    end

    def run_analytics
      ConversationCreate.perform_async(inviter.id, conversation.id, phones)
    end
  end
end
